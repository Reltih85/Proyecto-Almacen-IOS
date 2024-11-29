//
//  Usuario.swift
//  BernaolaSnapchat
//
//  Created by Frankbp on 21/10/24.
//

import Foundation
import FirebaseAuth

class Usuario {
    var email: String = ""
    var uid: String = ""

    static func obtenerUsuarioActual(completion: @escaping (Usuario?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("No hay usuario autenticado.")
            completion(nil)
            return
        }
        //Extraccion del Usuario Ingresado
        let usuarioActual = Usuario()
        usuarioActual.uid = user.uid
        usuarioActual.email = user.email ?? ""
        completion(usuarioActual)
    }
}
