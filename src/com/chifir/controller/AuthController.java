package com.chifir.controller;

import com.chifir.dto.AuthResponse;
import com.chifir.dto.LoginRequest;
import com.chifir.dto.RegisterRequest;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

@Controller
public class AuthController {

    @GetMapping("/")
    public String home() {
        return "dashboard";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/register")
    public String register() {
        return "register";
    }
}