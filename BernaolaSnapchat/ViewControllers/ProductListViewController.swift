import UIKit
import FirebaseFirestore

class ProductListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var categoryName: String?
    var products = [Product]()
    var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = categoryName
        
        // Configurar la tabla
        tableView.delegate = self
        tableView.dataSource = self
        
        // Cargar productos
        loadProducts()
    }
    
    // MARK: - Cargar Productos
    func loadProducts() {
        guard let category = categoryName else { return }
        let db = Firestore.firestore()
        
        listener = db.collection("products")
            .whereField("category", isEqualTo: category)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error al cargar los productos: \(error.localizedDescription)")
                    return
                }
                
                self.products = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let stock = data["stock"] as? Int ?? 0
                    let price = data["price"] as? Double ?? 0.0
                    let imageUrl = data["imageUrl"] as? String
                    let documentId = doc.documentID
                    
                    return Product(name: name, price: price, stock: stock, imageUrl: imageUrl, documentId: documentId)
                } ?? []
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: - UITableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        let product = products[indexPath.row]
        cell.textLabel?.text = "\(product.name) - Precio: \(product.price)"
        return cell
    }
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = products[indexPath.row]
        
        // Llama al segue con el producto seleccionado
        performSegue(withIdentifier: "showProductDetailSegue", sender: selectedProduct)
    }
    
    // MARK: - Preparar datos para el segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProductDetailSegue",
           let detailsVC = segue.destination as? detailsProductViewController,
           let selectedProduct = sender as? Product {
            detailsVC.product = selectedProduct
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Eliminar Productos
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let productToDelete = products[indexPath.row]
            let db = Firestore.firestore()
            
            // Eliminar el producto de Firestore
            db.collection("products").document(productToDelete.documentId).delete { error in
                if let error = error {
                    print("Error al eliminar el producto: \(error.localizedDescription)")
                } else {
                    print("Producto eliminado exitosamente.")
                    self.products.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }

    
}
