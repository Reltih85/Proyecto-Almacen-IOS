//
//  ViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 14/10/24.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class inicarSesionViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var iniciarSesionButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setDynamicBackground()
    }
    
    //MARK: BACKGRAGROUND
    
    func setDynamicBackground() {
        // Configurar el botón con relieve 3D
        iniciarSesionButton.layer.cornerRadius = 10
        iniciarSesionButton.backgroundColor = UIColor.systemBlue
        iniciarSesionButton.setTitleColor(.white, for: .normal)
        iniciarSesionButton.layer.shadowColor = UIColor.black.cgColor
        iniciarSesionButton.layer.shadowOpacity = 0.4
        iniciarSesionButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        iniciarSesionButton.layer.shadowRadius = 5
        iniciarSesionButton.layer.masksToBounds = false

        // Agregar sombra a la parte inferior de los campos de texto
        let textFields = [emailTextField, passwordTextField]
        textFields.forEach { textField in
            textField?.layer.shadowColor = UIColor.gray.cgColor
            textField?.layer.shadowOpacity = 0.3
            textField?.layer.shadowOffset = CGSize(width: 0, height: 2) // Sombra solo abajo
            textField?.layer.shadowRadius = 0 // Sin difuminado lateral
            textField?.layer.masksToBounds = false
        }
    }

    
    //MARK: BOTON INCIAR SESION
    @IBAction func IniciarSesionTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                print("Email o contraseña vacíos.")
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.mostrarAlertaUsuarioNoEncontrado(email: email, password: password)
                    print("Error: \(error.localizedDescription)")
                    return
                }

                print("Usuario autenticado exitosamente")

                guard let user = authResult?.user else {
                    print("Error: No se pudo obtener el usuario autenticado.")
                    return
                }

                let ref = Database.database().reference()
                let userRef = ref.child("usuarios").child(user.uid)

                userRef.updateChildValues(["email": email]) { error, _ in
                    if let error = error {
                        print("Error al guardar el email en la base de datos: \(error.localizedDescription)")
                        return
                    }
                    print("Email guardado correctamente en la base de datos.")
                    self.performSegue(withIdentifier: "iniciarsesionsegue", sender: nil)
                }
            }

    }
    
    func mostrarAlertaUsuarioNoEncontrado(email: String, password: String) {
            let alerta = UIAlertController(
                title: "Usuario no encontrado",
                message: "¿Deseas crear un nuevo usuario?",
                preferredStyle: .alert
            )
            
            let crearAccion = UIAlertAction(title: "Crear", style: .default) { _ in
                self.crearUsuario(email: email, password: password)
            }
            
            let cancelarAccion = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
            
            alerta.addAction(crearAccion)
            alerta.addAction(cancelarAccion)
            
            self.present(alerta, animated: true, completion: nil)
        }
        
        func crearUsuario(email: String, password: String) {
            // Navega a la pantalla de registro.
            self.performSegue(withIdentifier: "goToRegister", sender: nil)
        }
    
    
}
