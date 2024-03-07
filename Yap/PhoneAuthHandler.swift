//
//  PhoneAuthHandler.swift
//  Yap
//
//  Created by Yudi Lai on 3/5/24.
//

import Foundation
import Supabase

class PhoneAuthHandler {
    static let shared = PhoneAuthHandler()
    private var supabase: SupabaseClient?
    private var auth: AuthClient?
    
    private init() {
        guard let url = URL(string: "https://cijabnxjboineoojkpgs.supabase.co") else { return }
        guard let api_key = ProcessInfo.processInfo.environment["supabase_key"] else { return }
        supabase = SupabaseClient(supabaseURL: url, supabaseKey: api_key)
        if let supabase = supabase {
            self.auth = supabase.auth
        }
    }
    
    func signIn(phoneNum: String) async throws -> Void {
        print("signing in!")
        guard let supabase = supabase else { return }
        try await supabase.auth.signInWithOTP(phone: phoneNum)
    }
    
    func verifyOTP(phoneNum: String, otp: String) async throws -> Void {
        try await supabase?.auth.verifyOTP(
            phone: phoneNum,
            token: otp,
            type: .sms
        )
    }
}
