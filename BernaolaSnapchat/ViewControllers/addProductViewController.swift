import UIKit
import FirebaseFirestore

class addProductViewController: UIViewController {

    var categoryName: String? // Recibirá la categoría seleccionada

    @IBOutlet weak var productNameTextField: UITextField!
    @IBOutlet weak var stockTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var addProductButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let category = categoryName {
            self.title = "Añadir Producto a \(category)"
        }
        styleAddCategoryButton(addProductButton)
    }
    
    //MARK: Edicion de boton
    func styleAddCategoryButton(_ button: UIButton) {
        // Fondo del botón
        button.backgroundColor = UIColor.systemBlue

        // Bordes redondeados
        button.layer.cornerRadius = 10 // Suaviza las esquinas
        button.clipsToBounds = true

        // Sombras ligeras
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2) // Sombra hacia abajo
        button.layer.shadowOpacity = 0.3 // Transparencia de la sombra
        button.layer.shadowRadius = 5 // Difuminado de la sombra

        // Estilo del texto
        button.setTitleColor(.white, for: .normal) // Texto blanco
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold) // Fuente moderna
    }
    

    @IBAction func addProductTapped(_ sender: Any) {
        guard let productName = productNameTextField.text, !productName.isEmpty else {
            print("El nombre del producto está vacío")
            return
        }
        guard let stockText = stockTextField.text,
              let stock = Int(stockText),
              stock >= 0 else {
            print("Stock inválido")
            return
        }
        guard let priceText = priceTextField.text,
              let price = Double(priceText),
              price > 0 else {
            print("Precio inválido")
            return
        }
        guard let category = categoryName else {
            print("Categoría no especificada")
            return
        }

        saveProductToFirestore(name: productName, stock: stock, price: price, category: category)
    }

    func saveProductToFirestore(name: String, stock: Int, price: Double, category: String) {
        let db = Firestore.firestore()
        db.collection("products").addDocument(data: [
            "name": name,
            "stock": stock,
            "price": price,
            "category": category
        ]) { error in
            if let error = error {
                print("Error al guardar el producto: \(error.localizedDescription)")
            } else {
                print("Producto guardado exitosamente.")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
