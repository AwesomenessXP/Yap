//
//  PhoneAuthHandler.swift
//  Yap
//
//  Created by Yudi Lai on 3/5/24.
//

import Foundation
import Supabase

class PhoneAuthHandler{
    
    private var supabase: SupabaseClient?
    private init(){
        if let url = URL(string: "https://xyzcompany.supabase.co"){
            let api_key = ProcessInfo.processInfo.environment["SupabaseAPI_key"] ?? ""
            supabase = SupabaseClient(supabaseURL: url, supabaseKey: api_key)
        }
    }
    
    func verifyOTP(phoneNum: String, otp: String) async throws -> Void {
        try await supabase?.auth.verifyOTP(
            phone: phoneNum,
            token: otp,
            type: .sms
        )
    }
    
    // not sure how to send otp with twilio
    func signIn(phoneNum: String) async throws -> Void{
        try await supabase?.auth.signInWithOTP(
            phone: phoneNum
        )
    }
    /// Log in user using a one-time password (OTP)..
    ///
    /// - Parameters:
    ///   - phone: User's phone with international prefix.
    ///   - shouldCreateUser: Creates a new user, defaults to `true`.
    ///   - data: User's metadata.
    ///   - captchaToken: Captcha verification token.


    func signUp(phoneNum: String, password: String) async throws -> Void{
        var user = try await supabase?.auth.signUp(
            phone: phoneNum,
            password: password
        )
    }
    /// Creates a new user.
    /// - Parameters:
    ///   - phone: User's phone number with international prefix.
    ///   - password: Password for the user.
    ///   - data: User's metadata.
}
