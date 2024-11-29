//
//  AlmacenViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 20/11/24.
//

import UIKit
import FirebaseFirestore

class AlmacenViewController:  UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var warehouses = [(name: String, latitude: Double, longitude: Double)]()
    //Actializacion momentaneo
    var listener : ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Almacenes"
        
        // Configuración de la tabla
        tableView.delegate = self
        tableView.dataSource = self
        listenToWarehouses()

    }
    
    // MARK: - Actualizacion de tabla
    
    func listenToWarehouses() {
        let db = Firestore.firestore()
        
        // Configurar el listener
        listener = db.collection("warehouses").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error al escuchar cambios en almacenes: \(error.localizedDescription)")
                return
            }
            
            self?.warehouses = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard
                    let name = data["name"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double
                else {
                    return nil
                }
                return (name: name, latitude: latitude, longitude: longitude)
            } ?? []
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return warehouses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WarehouseCell", for: indexPath)
        let warehouse = warehouses[indexPath.row]
        
        cell.textLabel?.text = "🕌 \(warehouse.name)"
        
        // Subtítulo con coordenadas
        cell.detailTextLabel?.text = "Lat: \(warehouse.latitude), Lon: \(warehouse.longitude)"
        
        return cell
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMapSegue",
           let mapVC = segue.destination as? MapViewController {
            mapVC.onSave = { [weak self] name, latitude, longitude in
                self?.warehouses.append((name: name, latitude: latitude, longitude: longitude))
                self?.tableView.reloadData()
            }
        }
    }
    deinit {
        listener?.remove()
    }
    
    // MARK: - Eliminar Almacén al deslizar
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let warehouseToDelete = warehouses[indexPath.row]
            
            // Eliminar del Firestore
            let db = Firestore.firestore()
            db.collection("warehouses").whereField("name", isEqualTo: warehouseToDelete.name).getDocuments { snapshot, error in
                if let error = error {
                    print("Error al buscar el almacén para eliminar: \(error.localizedDescription)")
                    return
                }
                
                // Eliminar el documento en Firebase
                snapshot?.documents.first?.reference.delete { error in
                    if let error = error {
                        print("Error al eliminar el almacén: \(error.localizedDescription)")
                    } else {
                        print("Almacén eliminado correctamente.")
                        
                        // Eliminar del modelo local y actualizar la tabla
                        self.warehouses.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
    }
}
