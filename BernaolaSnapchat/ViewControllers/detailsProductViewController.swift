//
//  detailsProductViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 18/11/24.
//

import UIKit
import FirebaseFirestore
import Firebase
import FirebaseStorage


class detailsProductViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var productStockLabel: UILabel!

    var product: Product?
    let db = Firestore.firestore()
    let storage = Storage.storage()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()

        // Hacer que la imagen sea interactiva
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        productImageView.addGestureRecognizer(tapGesture)
        productImageView.isUserInteractionEnabled = true
    }

    func setupUI() {
        guard let product = product else { return }
        productNameLabel.text = "Nombre: \(product.name)"
        productPriceLabel.text = "Precio: \(product.price)"
        productStockLabel.text = "Stock: \(product.stock)"
    }

    func loadImage() {
        guard let product = product, let imageUrl = product.imageUrl else { return }
        let storageRef = storage.reference(forURL: imageUrl)
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error al descargar la imagen: \(error.localizedDescription)")
                return
            }
            if let data = data, let image = UIImage(data: data) {
                self.productImageView.image = image
            }
        }
    }

    @objc func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            productImageView.image = selectedImage
            uploadImageToFirebase(image: selectedImage)
        }
        dismiss(animated: false, completion: nil)
    }

    func uploadImageToFirebase(image: UIImage) {
        guard let product = product else { return }
        let storageRef = storage.reference().child("product_images/\(product.name)_\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error al subir la imagen: \(error.localizedDescription)")
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error al obtener la URL de la imagen: \(error.localizedDescription)")
                    return
                }
                if let url = url {
                    self.saveImageURLToFirestore(url: url.absoluteString)
                }
            }
        }
    }

    func saveImageURLToFirestore(url: String) {
        guard let product = product else { return }
        db.collection("products").document(product.documentId).updateData([
            "imageUrl": url
        ]) { error in
            if let error = error {
                print("Error al guardar la URL de la imagen en Firestore: \(error.localizedDescription)")
            } else {
                print("URL de la imagen guardada exitosamente.")
            }
        }
    }
}
