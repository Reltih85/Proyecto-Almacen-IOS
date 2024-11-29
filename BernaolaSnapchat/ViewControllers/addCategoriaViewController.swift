import UIKit
import FirebaseFirestore

class addCategoriaViewController: UIViewController {

    @IBOutlet weak var nameCategoryTextField: UITextField!
    @IBOutlet weak var cantidadPaquetesTextField: UITextField!
    @IBOutlet weak var stockTextField: UITextField!
    @IBOutlet weak var addCategoryButton: UIButton! //Para añadir estilo
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Añadir Nueva Categoría"
        styleAddCategoryButton(addCategoryButton)
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


    
    @IBAction func btnCrearCategoriaTapped(_ sender: Any) {
        guard let name = nameCategoryTextField.text, !name.isEmpty else {
            print("El nombre de la categoría está vacío")
            return
        }
        guard let cantidadPaquetesText = cantidadPaquetesTextField.text,
              let cantidadPaquetes = Int(cantidadPaquetesText),
              cantidadPaquetes > 0 else {
            print("Cantidad de paquetes inválida")
            return
        }
        guard let stockText = stockTextField.text,
              let stock = Int(stockText),
              stock >= 0 else {
            print("Stock inválido")
            return
        }

        saveCategoryToFirestore(name: name, cantidadPaquetes: cantidadPaquetes, stock: stock)
    }

    func saveCategoryToFirestore(name: String, cantidadPaquetes: Int, stock: Int) {
        let db = Firestore.firestore()
        db.collection("categories").addDocument(data: [
            "name": name,
            "cantidadPaquetes": cantidadPaquetes,
            "stock": stock,
            "date": Date() // Agrega la fecha actual
        ]) { error in
            if let error = error {
                print("Error al guardar la categoría: \(error.localizedDescription)")
            } else {
                print("Categoría guardada exitosamente.")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
