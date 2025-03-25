//
//  NoteBody.swift
//  NoteBlocks App
//
//  Created by Deyan on 22.02.25.
//

import SwiftUI
import UIKit

struct CustomTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    @State private var isEditing = false

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextView

        init(parent: CustomTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isEditing = false
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let textView = sender.view as? UITextView else { return }
            if parent.isEditing {
                textView.resignFirstResponder() // Dismiss keyboard on second tap
                parent.isEditing = false
            } else {
                textView.becomeFirstResponder() // Focus on first tap
                parent.isEditing = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textColor = UIColor.label
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 10
        textView.returnKeyType = .done
        textView.autocapitalizationType = .sentences

        // Initialize with the placeholder if no text is provided
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        }

        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textView.addGestureRecognizer(tapGesture)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if isEditing {
            uiView.textColor = UIColor.label
            if uiView.text == placeholder {
                uiView.text = ""
            }
        } else {
            if text.isEmpty {
                uiView.text = placeholder
                uiView.textColor = UIColor.lightGray
            } else {
                uiView.text = text
                uiView.textColor = UIColor.label
            }
        }
    }
}


struct NoteBody: View {
    @Binding var text: String

    var body: some View {
        VStack(spacing: 10) {  // Set spacing to 0 to remove space between elements
            // Custom TextView for typing (no padding)
            CustomTextView(text: $text, placeholder: "Enter your text here...")
                            .frame(maxWidth: 375, minHeight: 75) // Increased height
                            .padding(.top, 0) // Remove top padding
                            .padding(.bottom, 0) // Remove bottom padding
        }
    }
}

