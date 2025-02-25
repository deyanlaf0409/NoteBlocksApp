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
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textColor = UIColor.label // Default text color
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 10
        textView.layer.borderWidth = 0  // Removed the border
        textView.returnKeyType = .done
        textView.autocapitalizationType = .sentences

        // Initialize with the placeholder if no text is provided
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        }

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

