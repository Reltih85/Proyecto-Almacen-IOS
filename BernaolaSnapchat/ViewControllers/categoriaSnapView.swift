//
//  categoriaSnapView.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 21/10/24.
//

import UIKit
import FirebaseFirestore

class categoriaSnapView: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var categoriTable: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    //MARK: outlet para ser personalizado
    @IBOutlet weak var chatVozButton: UIButton!
    @IBOutlet weak var almacenesButton: UIButton!
    
    var categories = [Category]()
    var filteredCategories = [Category]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Categorías"
        styleSimpleButtons()
        // Configurar la tabla y el campo de búsqueda
        categoriTable.delegate = self
        categoriTable.dataSource = self
        categoriTable.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)
        
        // Cargar las categorías iniciales
        loadCategories()
    }
    //MARK: ESTILO DE BOTONES
    func styleSimpleButtons() {
        let buttons = [chatVozButton, almacenesButton] // Reemplaza con tus botones

        for button in buttons {
            guard let button = button else { continue }

            // Fondo de color sólido
            if button == chatVozButton {
                button.backgroundColor = UIColor.systemRed // Fondo rojo
            } else if button == almacenesButton {
                button.backgroundColor = UIColor.systemBlue // Fondo azul
            }

            // Sombras simples
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowOpacity = 0.2 // Sombra sutil
            button.layer.shadowRadius = 4

            // Bordes y esquinas redondeadas
            button.layer.cornerRadius = 6 // Redondeado sutil
            button.clipsToBounds = false

            // Texto
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14) // Texto claro y profesional
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Volver a cargar las categorías cada vez que la vista aparece
        loadCategories()
    }
    
    func loadCategories() {
        let db = Firestore.firestore()
        db.collection("categories").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error al cargar las categorías: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("No se encontraron datos.")
                return
            }

            self.categories = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let cantidadPaquetes = data["cantidadPaquetes"] as? Int ?? 0
                let stock = data["stock"] as? Int ?? 0
                return Category(name: name, date: "", cantidadPaquetes: cantidadPaquetes, stock: stock)
            }
            
            self.filteredCategories = self.categories
            self.categoriTable.reloadData()
        }
    }
    
    // Número de filas
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCategories.count
    }
    
    // Configuración de celdas
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = filteredCategories[indexPath.row]
        
        cell.textLabel?.text = category.name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.textLabel?.textColor = UIColor.darkGray
        
        // Personalizar el fondo de las celdas
        cell.backgroundColor = UIColor(white: 0.95, alpha: 1)
        cell.layer.cornerRadius = 8
        cell.layer.masksToBounds = true
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5

        return cell
    }

    
    // Eliminar categorías al deslizar
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let categoryToDelete = filteredCategories[indexPath.row]
            deleteCategory(categoryToDelete)
        }
    }
    
    func deleteCategory(_ category: Category) {
        let db = Firestore.firestore()
        db.collection("categories").whereField("name", isEqualTo: category.name).getDocuments { snapshot, error in
            if let error = error {
                print("Error al buscar la categoría: \(error.localizedDescription)")
                return
            }
            
            snapshot?.documents.first?.reference.delete { error in
                if let error = error {
                    print("Error al eliminar la categoría: \(error.localizedDescription)")
                } else {
                    print("Categoría eliminada exitosamente.")
                    self.loadCategories() // Recargar después de eliminar
                }
            }
        }
    }
    
    // Buscar categorías
    @objc func searchTextChanged(_ textField: UITextField) {
        guard let searchText = textField.text, !searchText.isEmpty else {
            filteredCategories = categories
            categoriTable.reloadData()
            return
        }

        filteredCategories = categories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        categoriTable.reloadData()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        filteredCategories = categories
        categoriTable.reloadData()
        return true
    }
    
    @IBAction func addCategoryTapped(_ sender: Any) {
        performSegue(withIdentifier: "addCategorySegue", sender: self)
    }

    @IBAction func cerrarTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func editProfile(_ sender: Any) {
        performSegue(withIdentifier: "editarPerfilSegue", sender: self)
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCategory = filteredCategories[indexPath.row]
        performSegue(withIdentifier: "ProductListSegue", sender: selectedCategory.name)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProductListSegue" {
            if let destinationVC = segue.destination as? ProductListViewController,
               let selectedCategory = sender as? String {
                destinationVC.categoryName = selectedCategory
            }
        }
    }
}
