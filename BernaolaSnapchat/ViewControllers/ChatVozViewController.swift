//
//  ChatVozViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 20/11/24.
//

import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class ChatVozViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!

    var audioRecorder: AVAudioRecorder?
    var audioFileName: URL?
    var recordingTimer: Timer?
    var recordingStartTime: Date?
    var audios = [(email: String, duration: String, audioUrl: String)]()
    var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configuración inicial
        stopButton.isEnabled = false
        tableView.delegate = self
        tableView.dataSource = self

        // Configurar grabadora de audio
        setupAudioRecorder()

        // Escuchar datos en Firebase
        listenToAudios()
    }

    // MARK: - Configuración del Grabador
    func setupAudioRecorder() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        audioFileName = urls[0].appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName!, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Error al configurar la grabadora de audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Botones de Grabación
    @IBAction func startRecording(_ sender: UIButton) {
        guard let recorder = audioRecorder else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            recorder.record()
            print("Grabacion iniciada")
            recordingStartTime = Date()
            startRecordingTimer()

            recordButton.isEnabled = false
            stopButton.isEnabled = true
        } catch {
            print("Error al iniciar la grabación: \(error.localizedDescription)")
        }
    }

    @IBAction func stopRecording(_ sender: UIButton) {
        guard let recorder = audioRecorder else { return }

        recorder.stop()
        print("Grabacion detenida")
        recordingTimer?.invalidate()
        durationLabel.text = "0:00"
        saveAudioToFirebase()

        recordButton.isEnabled = true
        stopButton.isEnabled = false
    }

    // MARK: - Timer de Grabación
    func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let startTime = self?.recordingStartTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let minutes = Int(elapsed) / 60
            let seconds = Int(elapsed) % 60
            self?.durationLabel.text = String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Guardar Audio en Firebase
    func saveAudioToFirebase() {
        guard let fileName = audioFileName, let currentUser = Auth.auth().currentUser else { return }

        let storageRef = Storage.storage().reference().child("audios/\(UUID().uuidString).m4a")
        storageRef.putFile(from: fileName, metadata: nil) { metadata, error in
            if let error = error {
                print("Error al subir el audio: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error al obtener la URL del audio: \(error.localizedDescription)")
                    return
                }

                guard let url = url else { return }
                let duration = self.getAudioDuration(url: fileName)

                let db = Firestore.firestore()
                db.collection("audios").addDocument(data: [
                    "userEmail": currentUser.email ?? "Desconocido",
                    "duration": duration,
                    "audioUrl": url.absoluteString,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error al guardar la información del audio: \(error.localizedDescription)")
                    } else {
                        print("Audio guardado exitosamente.")
                    }
                }
            }
        }
    }

    func getAudioDuration(url: URL) -> String {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        return String(format: "%.1f segundos", durationInSeconds)
    }

    // MARK: - Escuchar Cambios en Firestore
    func listenToAudios() {
        let db = Firestore.firestore()
        listener = db.collection("audios").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error al escuchar cambios: \(error.localizedDescription)")
                return
            }

            self?.audios = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                guard
                    let email = data["userEmail"] as? String,
                    let duration = data["duration"] as? String,
                    let audioUrl = data["audioUrl"] as? String
                else {
                    print("Error al procesar documento: \(doc.data())")
                    return nil
                }
                print("Audio cargado: \(email), \(duration), \(audioUrl)")
                return (email: email, duration: duration, audioUrl: audioUrl)
            } ?? []

            DispatchQueue.main.async {
                print("Recargado en la tabla: \(self?.audios.count ?? 0) audios")
                self?.tableView.reloadData()
            }
        }
    }

    deinit {
        listener?.remove()
    }

    // MARK: - UITableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioCell", for: indexPath)
        let audio = audios[indexPath.row]
        cell.textLabel?.text = audio.email
        cell.detailTextLabel?.text = "\(audio.duration)"
        return cell
    }

    // MARK: - Eliminar Audio
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let audioToDelete = audios[indexPath.row]
            let db = Firestore.firestore()
            db.collection("audios").whereField("audioUrl", isEqualTo: audioToDelete.audioUrl).getDocuments { snapshot, error in
                if let error = error {
                    print("Error al buscar el audio para eliminar: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else { return }
                document.reference.delete { error in
                    if let error = error {
                        print("Error al eliminar el audio: \(error.localizedDescription)")
                    } else {
                        print("Audio eliminado exitosamente.")
                    }
                }
            }
        }
    }
    // MARK: - Reproducir Audio
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAudio = audios[indexPath.row]

        // Accedemos al audio desde Firebase Storage
        let storageRef = Storage.storage().reference(forURL: selectedAudio.audioUrl)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempAudio.m4a")

        // Descargar el audio
        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Error al descargar el audio: \(error.localizedDescription)")
                return
            }

            // Reproducir el audio descargado
            self.playAudio(fileURL: localURL)
        }
    }
    var audioPlayer: AVAudioPlayer?

    func playAudio(fileURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.play()
            print("Reproduciendo audio desde: \(fileURL)")
        } catch {
            print("Error al reproducir el audio: \(error.localizedDescription)")
        }
    }

}
