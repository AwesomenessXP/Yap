//
//  PhoneAuthHandler.swift
//  Yap
//
//  Created by Yudi Lai on 3/5/24.
//

import Foundation
import Supabase

class PhoneAuthHandler: ObservableObject {
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
    
    func signIn(phoneNum: String) async throws -> Bool {
        guard let supabase = supabase else { return false }
        try await supabase.auth.signInWithOTP(phone: phoneNum)
        return true
    }
    
    func verifyOTP(phoneNum: String, otp: String) async throws -> Bool {
        guard let supabase = supabase else { return false }
        try await supabase.auth.verifyOTP(
            phone: phoneNum,
            token: otp,
            type: .sms
        )
        return true
    }
    
    func listenForAuth() async {
        guard let supabase = supabase else { return }
        for await (event, session) in await supabase.auth.authStateChanges {
            if event == .signedIn {
                
            }
        }
    }
}
