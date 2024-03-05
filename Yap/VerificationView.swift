//
//  VerificationView.swift
//  Yap
//
//  Created by Jackie Trinh on 3/5/24.
//

//
//  VerificationView.swift
//  TestRandom
//
//  Created by Jackie Trinh on 3/5/24.
//


import SwiftUI

struct VerificationView: View {
    @State private var otpFields: [String] = Array(repeating: "", count: 6)
    var phoneNumber: String

    var body: some View {
        VStack {
            Text("Verify your number")
                .font(.title2).bold()
                .foregroundColor(.white)
                .padding()

            HStack {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $otpFields[index])
                        .frame(width: 40, height: 40)
                        .multilineTextAlignment(.center)
                        .keyboardType(.phonePad)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                }
            }

            Text("Verification code sent to \(phoneNumber)")
                .foregroundColor(Color.gray)
                .font(.subheadline)
                .padding()
            GeometryReader { geometry in
                Button("Resend Code") {}
                    .frame(width: 330, height: 50)
                    .foregroundStyle(.black)
                    .bold()
                    .background(Color.white)
                    .cornerRadius(15)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct VerificationView_Previews: PreviewProvider {
    static var previews: some View {
        VerificationView(phoneNumber: "123-456-7890")
    }
}

