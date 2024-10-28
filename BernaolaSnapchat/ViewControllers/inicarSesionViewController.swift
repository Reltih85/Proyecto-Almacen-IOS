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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func IniciarSesionTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
                
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        // Si el usuario no existe, muestra una alerta.
                        self.mostrarAlertaUsuarioNoEncontrado(email: email, password: password)
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    // Si el usuario existe, continúa a la siguiente vista.
                    print("Usuario autenticado exitosamente")
                    self.performSegue(withIdentifier: "iniciarsesionsegue", sender: nil)
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
