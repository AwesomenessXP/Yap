import SwiftUI
import PhoneNumberKit

struct SignUpView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var label: PhoneNumModel
    @FocusState var isFocused: Bool
    @Binding var usernameSet: Bool
    @Binding var username: String
    @Binding var phoneNum: String
    @Binding var formattedNum: String
    @State private var phoneNumberKit = PhoneNumberKit()
    @State private var btnDisabled: Bool = true
    
    var body: some View {
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
            }
            Group {
                Spacer().frame(height: 10)
                UsernameField
                PhoneNumField
                Spacer().frame(height: 10)
            }
            .background(RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.45), lineWidth: 2))
            .padding()
            Spacer()
            
            SignUpBtn(isLogin: $usernameSet, username: $username, btnDisabled: $btnDisabled)
            Spacer()
                .frame(height: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    var UsernameField: some View {
        TextField("Make a username", text: $username)
            .bold()
            .colorScheme(.dark)
            .foregroundStyle(.white)
            .padding(.leading, 20)
            .frame(width: 330, height: 50)
            .onChange(of: username) { newValue in
                checkBtnDisabled()
            }
    }
    
    var PhoneNumField: some View {
        HStack {
            Text("+1")
                .foregroundStyle(.gray.opacity(0.5))
                .bold()
            Divider()
                .frame(width: 1.5, height: 24)
                .overlay(Color.gray)
            TextField("(999) 999 - 9999", text: $phoneNum)
                .bold()
                .colorScheme(.dark)
                .foregroundStyle(.white)
                .padding([.top, .bottom], 15)
        }
        .onTapGesture {
            self.isFocused = true
        }
        .keyboardType(.numberPad)
        .onChange(of: phoneNum) { newValue in
            var unformatted = label.unformatNum(number: newValue)
            unformatted = String(unformatted.prefix(label.MAXDIGITS))
            phoneNum = PartialFormatter().formatPartial(unformatted)
            formattedNum = label.asYouType (
                number: phoneNum,
                phoneNumberKit: phoneNumberKit,
                formattedNumber: $formattedNum
            )
            print("formatted num: \(formattedNum)")
            label.updateLabel(number: phoneNum)
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
        VStack() {
            HStack {
                Spacer()
                Toggle(isOn: $eulaAccepted) {
                    HStack(spacing: 1) {
                        Text("I accept the ")
                            .fontWeight(.regular).foregroundStyle(.white)
                        Link("Terms and Conditions", destination: URL(string: termsUrl)!)
                            .foregroundStyle(.gray).fontWeight(.bold)
                    }
                }
                .toggleStyle(CheckboxToggleStyle())
                .font(.system(size: 12))
                Spacer()
            }
            Text(error)
                .foregroundStyle(.red)
            Text(unsentError)
                .foregroundStyle(.red)
            Spacer()
            Spacer()
        }
        
        GeometryReader { geometry in // grab the screen size
            Button(action: { Task {
                let usernameAdd = await self.settingsModel.addUsername(name: username)
                if (usernameAdd.0 && usernameAdd.2 == .clean) {
                    self.isLogin = true
                } else {
                    error = usernameAdd.1
                    if usernameAdd.2 == .offensive {
                        unsentError = "Please choose an appropriate name next time"
                    }
                }
                
            }}) {
                Text("Continue to Auth")
                    .fontWeight(.semibold)
                    .frame(width: 360, height: 50)
            }
            .frame(width: 330, height: 50)
            .foregroundStyle(.black)
            .bold()
            .onChange(of: username, perform: {
                username in
                if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    error = ""
                    self.btnDisabled = false
                }
                else {
                    self.btnDisabled = true
                }
            })
            .disabled(!self.eulaAccepted && self.btnDisabled && label.isDisabled)
            .background(self.eulaAccepted && !self.btnDisabled ? Color.white : Color.gray.opacity(0.5))
            .cornerRadius(15)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
            
        }

    }
}

#Preview {
    SignUpView(usernameSet: .constant(true), username: .constant(""), phoneNum: .constant(""), formattedNum: .constant(""))
        .environmentObject(SettingsModel())
        .environmentObject(PhoneNumModel())
}
