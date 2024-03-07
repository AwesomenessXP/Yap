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
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var label: PhoneNumModel
    @State private var otpFields: [String] = Array(repeating: " ", count: 6)
    @State private var previousOTPValues = Array(repeating: " ", count: 6)
    @FocusState private var focusedField: Int?
    @Binding var username: String
    @Binding var isLogin: Bool
    @Binding var error: String
    @Binding var unsentError: String

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
                        .foregroundStyle(.white)
                        .onTapGesture {
                            // dont let the user tap anywhere
                            if focusedField != index {
                                focusedField = focusedField
                            }
                        }
                        .focused($focusedField, equals: index)
                        .tag(index)
                        .onChange(of: otpFields[index]) { newOTP in
                            moveToNextField(
                                oldValue: previousOTPValues[index],
                                newValue: newOTP, digit: index
                            )
                            if let last = newOTP.last {
                                previousOTPValues[index] = String(last)
                            }
                            else {
                                previousOTPValues[index] = " "
                            }
                        }
                }
            }

            Text("Verification code sent to \(label.phoneNum)")
                .foregroundColor(Color.gray)
                .font(.subheadline)
                .padding()
            GeometryReader { geometry in
                Button("Resend Code") {
                    DispatchQueue.main.async {
                        focusedField = 0
                        otpFields = Array(repeating: " ", count: 6)
                    }
                    Task {
                        await sendOTP()
                    }
                }
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
        .onAppear() {
            focusedField = 0
            Task {
                await sendOTP()
            }
        }
        .alert("YAP needs to use your location to access your messages", isPresented: .constant(!LocationManager.shared.isAuthorized()), actions: {
            Button("OK", role: .cancel) {}
        })
    }
    
    func startVerify() async {
        let verified = await verifyOTP()
        if verified {
            let usernameAdd = await self.settingsModel.addUsername(name: username)
            if (usernameAdd.0 && usernameAdd.2 == .clean) {
                DispatchQueue.main.async {
                    self.isLogin = true
                    print("logged in!")
                }
            } else {
                self.error = usernameAdd.1
                if usernameAdd.2 == .offensive {
                    self.unsentError = "Please choose an appropriate name next time"
                }
            }
        }
    }
    
    func verifyToken() async {
        let token = UserDefaults.standard.value(forKey: "user_token")
        let getUser = settingsModel.getUsername()
        self.isLogin = (token == nil || getUser == nil) ? false : true
        self.username = getUser ?? ""
    }
    
    func sendOTP() async -> Bool {
        do {
            return try await PhoneAuthHandler.shared.signIn(phoneNum: label.phoneNum)
        }
        catch {
            print("Error signing in: \(error.localizedDescription)")
        }
        return false
    }
    
    func verifyOTP() async -> Bool {
        do {
            let concat = otpFields.compactMap{$0}.joined(separator: "")
            return try await PhoneAuthHandler.shared.verifyOTP(
                phoneNum: label.phoneNum,
                otp: concat
            )
        }
        catch {
            print("Error verifying: \(error.localizedDescription)")
        }
        return false
    }
    
    func moveToNextField(oldValue: String, newValue: String, digit: Int) {
        if newValue.count > 1 {
            if oldValue != " " {
                otpFields[digit] = oldValue
                if digit < 5 {
                    otpFields[digit+1] = newValue
                }
            }
            else {
                otpFields[digit] = String(newValue.suffix(1))
            }
            focusedField = (focusedField ?? 0) + 1
        }
        else if newValue.count == 0 {
            otpFields[digit] = " "
            focusedField = (focusedField ?? 0) - 1
        }// else if
        else if otpFields[5] != " " {
            Task {
                await startVerify()
            }
        }
    }
}

#Preview {
    VerificationView(username: .constant(""), isLogin: .constant(false), error: .constant(""), unsentError: .constant(""))
        .environmentObject(SettingsModel())
        .environmentObject(PhoneNumModel())
}
