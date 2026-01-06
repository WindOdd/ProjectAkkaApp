//
//  UIKitTextField.swift
//  ProjectAkkaApp
//
//  UIKit UITextField 包裝 - 解決 SwiftUI TextField 鍵盤 constraint 問題
//

import SwiftUI
import UIKit

struct UIKitTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textAlignment: NSTextAlignment = .right
    var onEditingChanged: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textAlignment = textAlignment
        textField.delegate = context.coordinator
        textField.borderStyle = .none
        textField.font = .preferredFont(forTextStyle: .body)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        
        // 添加 toolbar 用於收起鍵盤
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "完成", style: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        // 監聽文字變化
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitTextField
        
        init(_ parent: UIKitTextField) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingChanged?(true)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged?(false)
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        UIKitTextField(
            placeholder: "請輸入 IP",
            text: .constant("192.168.1.100"),
            keyboardType: .decimalPad
        )
        .frame(height: 44)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    .padding()
}
