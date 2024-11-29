//
//  editProfileViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 18/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

class editProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var editarButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageView()
        loadUserData()
        styleEditButton()
    }

    //MARK: EDICION DE BOTON
    
    func styleEditButton() {
        editarButton.layer.cornerRadius = 8 // Esquinas redondeadas
        editarButton.layer.masksToBounds = false
        editarButton.layer.shadowColor = UIColor.white.cgColor
        editarButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        editarButton.layer.shadowOpacity = 0.25 // Opacidad de la sombra
        editarButton.layer.shadowRadius = 4 // Difuminado de la sombra
        editarButton.backgroundColor = UIColor.systemBlue // Color del botón
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Asegurarse de que la imagen sea perfectamente circular
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.masksToBounds = true
    }

    func setupProfileImageView() {
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeProfileImage))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }

    func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No hay usuario autenticado.")
            return
        }

        emailTextField.text = currentUser.email
        emailTextField.isUserInteractionEnabled = false

        loadImageFromStorage()
    }

    @objc func changeProfileImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.editedImage] as? UIImage {
            profileImageView.image = selectedImage
            saveImageToStorage(selectedImage)
        }
    }

    func saveImageToStorage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let currentUser = Auth.auth().currentUser else { return }

        let storageRef = Storage.storage().reference().child("profile_images/\(currentUser.uid).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error al guardar la imagen: \(error.localizedDescription)")
            } else {
                print("Imagen guardada exitosamente.")
            }
        }
    }

    func loadImageFromStorage() {
        guard let currentUser = Auth.auth().currentUser else { return }

        let storageRef = Storage.storage().reference().child("profile_images/\(currentUser.uid).jpg")
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error al cargar la imagen: \(error.localizedDescription)")
                return
            }

            guard let url = url else { return }
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }
            }
        }
    }

    @IBAction func updatePasswordTapped(_ sender: Any) {
        guard let newPassword = passwordTextField.text, !newPassword.isEmpty else {
            print("La contraseña no puede estar vacía.")
            return
        }

        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                print("Error al actualizar la contraseña: \(error.localizedDescription)")
            } else {
                print("Contraseña actualizada exitosamente.")
                self.passwordTextField.text = ""
            }
        }
    }
}
