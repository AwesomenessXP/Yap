import SwiftUI
import PhoneNumberKit

struct SignUpView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var phoneNumModel: PhoneNumModel
    @EnvironmentObject var label: PhoneNumModel
    @FocusState var isFocused: Bool
    @Binding var isLogin: Bool
    @Binding var username: String
    @Binding var phoneNum: String
    @Binding var formattedNum: String
    @State private var phoneNumberKit = PhoneNumberKit()
    @State private var btnDisabled: Bool = true
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    self.isFocused = false
                }
            VStack {
                Spacer().frame(height: 75)
                HStack {
                    Spacer()
                    Text("YAPPIN")
                        .font(.system(size: 36)).bold()
                        .foregroundColor(.white)
                        .italic()
                        .fontWeight(.heavy)
                    Spacer()
                }.padding(.bottom,5)
                HStack {
                    Spacer()
                    Text("Chat with people nearby you")
                        .font(.system(size: 18)).bold()
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Spacer()
                }.padding(.bottom, 10)
                Group {
                    UsernameField
                        .focused($isFocused)
                    PhoneNumField
                        .focused($isFocused)
                }
                .background(RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color.gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    ))
                .padding(.bottom, 8)
                Spacer()
                
                SignUpBtn(isLogin: $isLogin, username: $username, btnDisabled: $btnDisabled)

            }
            .onTapGesture {
                self.isFocused = false
            }
        }
    }
    
    var UsernameField: some View {
        TextField("Make a username", text: $username)
            .bold()
            .colorScheme(.dark)
            .foregroundStyle(.white)
            .padding(.leading, 20)
            .frame(width: 330, height: 50)
            .onChange(of: username, perform: {
                username in
                checkBtnDisabled()
                if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.btnDisabled = false
                }
                else {
                    self.btnDisabled = true
                }
            })
    }
    
    var PhoneNumField: some View {
        HStack {
            Text("+1")
                .foregroundStyle(.gray.opacity(0.5))
                .bold()
            Divider()
                .frame(width: 1.5, height: 24)
                .overlay(Color.gray)
            TextField("(999) 999-9999", text: $phoneNum)
                .bold()
                .colorScheme(.dark)
                .foregroundStyle(.white)
                .padding([.top, .bottom], 15)
        }
        .keyboardType(.numberPad)
        .onChange(of: phoneNum) { newValue in
            var unformatted = phoneNumModel.unformatNum(number: newValue)
            unformatted = String(unformatted.prefix(phoneNumModel.MAXDIGITS))
            phoneNum = PartialFormatter().formatPartial(unformatted)
            formattedNum = phoneNumModel.asYouType (
                number: phoneNum,
                phoneNumberKit: phoneNumberKit,
                formattedNumber: $formattedNum
            )
            print("formatted num: \(formattedNum)")
            phoneNumModel.updateLabel(number: phoneNum)
            checkBtnDisabled()
        }
        .padding([.trailing, .leading], 20)
        .frame(width: 330, height: 50)
    }
    
    func checkBtnDisabled() {
        if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.btnDisabled = false
        }
    }
}

struct SignUpBtn: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var label: PhoneNumModel
    @Binding var isLogin: Bool
    @Binding var username: String
    @State private var eulaAccepted = false
    let termsUrl = "https://lighthearted-mandazi-3d73bb.netlify.app/Yappin.pdf"
    @Binding var btnDisabled: Bool
    @State var error: String = ""
    @State var unsentError: String = ""
    
    var body: some View {
        VStack {
            if let url = URL(string: termsUrl) {
                HStack {
                    Spacer()
                    Toggle(isOn: $eulaAccepted) {
                        HStack(spacing: 1) {
                            Text("I accept the ")
                                .fontWeight(.regular).foregroundStyle(.white)
                            Link("Terms and Conditions", destination: url)
                                .foregroundStyle(.gray).fontWeight(.bold)
                        }
                    }
                    .padding()
                    .toggleStyle(CheckboxToggleStyle())
                    Spacer()
                }
            }
            Text(error)
                .foregroundStyle(.red)
            Text(unsentError)
                .foregroundStyle(.red)
            Spacer()
            Spacer()
        }.padding(.top,5)
        
        if self.eulaAccepted && !self.btnDisabled && !label.isDisabled {
            GeometryReader { geometry in // grab the screen size
                NavigationLink {
                    VerificationView(username: $username,
                                     isLogin: $isLogin,
                                     error: $error,
                                     unsentError: $unsentError)
                } label: {
                    Text("Send OTP")
                        .fontWeight(.semibold)
                        .frame(width: 360, height: 50)
                }
                .frame(width: 330, height: 50)
                .foregroundStyle(.black)
                .bold()
                .background(Color.white)
                .cornerRadius(15)
                .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
            }
        }
    }
}

#Preview {
    SignUpView(isLogin: .constant(true), username: .constant("haskmoney"), phoneNum: .constant(""), formattedNum: .constant(""))
        .environmentObject(SettingsModel())
        .environmentObject(PhoneNumModel())
}
