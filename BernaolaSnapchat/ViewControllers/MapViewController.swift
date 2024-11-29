//
//  MapViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 20/11/24.
//

import UIKit
import MapKit
import FirebaseFirestore

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var onSave: ((String, Double, Double) -> Void)? // Callback para guardar la ubicación seleccionada

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configuración del mapa
        mapView.delegate = self

        // Configurar una región predeterminada
        let defaultCoordinate = CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428) // Lima, Perú
        let region = MKCoordinateRegion(
            center: defaultCoordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)

        // Agregar gesto de toque largo para seleccionar ubicación
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Manejar gesto de toque largo en el mapa
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let locationInView = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
            
            // Limpiar pines anteriores
            mapView.removeAnnotations(mapView.annotations)
            
            // Añadir un pin en el mapa
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Ubicación seleccionada"
            mapView.addAnnotation(annotation)
            
            // Mostrar alerta para guardar
            presentSaveAlert(for: coordinate)
        }
    }

    // MARK: - Mostrar alerta para guardar la ubicación
    func presentSaveAlert(for coordinate: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "Guardar Almacén", message: "Introduce el nombre del almacén", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Nombre del almacén"
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default, handler: { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let latitude = coordinate.latitude
            let longitude = coordinate.longitude

            // Guardar en Firebase
            let db = Firestore.firestore()
            db.collection("warehouses").addDocument(data: [
                "name": name,
                "latitude": latitude,
                "longitude": longitude
            ]) { error in
                if let error = error {
                    print("Error al guardar el almacén: \(error.localizedDescription)")
                } else {
                    print("Almacén guardado en Firebase correctamente.")
                }
            }

            // Callback para actualizar la lista local
            self?.onSave?(name, latitude, longitude)
            self?.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Mapa dimensiones: \(mapView.frame.size)")
    }

}

