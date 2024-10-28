//
//  RegistroViewController.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 23/10/24.
//

import UIKit
import FirebaseAuth

class RegistroViewController: UIViewController {

    
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!
    
    func esEmailValido(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @IBAction func registrarTapped(_ sender: UIButton) {
        let email = emailTextField.text ?? ""
                let password = passwordTextField.text ?? ""

                // Crear usuario en Firebase sin validaciones locales
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        // Mostrar cualquier error que devuelva Firebase
                        self.mostrarAlerta(titulo: "Error", mensaje: error.localizedDescription)
                        print("Error creando usuario: \(error.localizedDescription)")
                        return
                    }
                    print("Usuario creado exitosamente")
                    // Volver a la pantalla de inicio de sesión
                    self.dismiss(animated: true, completion: nil)
                }
    }
    
    func mostrarAlerta(titulo: String, mensaje: String) {
            let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alerta, animated: true, completion: nil)
        }


}
