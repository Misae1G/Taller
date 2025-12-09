# 🔐 Taller Práctico: Sistema de Restablecimiento de Contraseña con Supabase y Flutter

## Descripción del Proyecto

Este taller te guiará paso a paso para implementar un sistema completo de restablecimiento de contraseña que incluye:

- **Backend**: Servidor Node.js con Express desplegado en Railway
- **Frontend Web**: Página HTML/CSS/JS para restablecer contraseña
- **Integración**: Supabase como servicio de autenticación
- **App Móvil**: Flutter como cliente que solicita el restablecimiento

---

## 📋 Requisitos Previos

### Software Necesario
- Node.js v14 o superior
- Git
- VS Code o editor de preferencia
- Flutter SDK
- Cuenta en Supabase
- Cuenta en Railway o Render
- Cuenta en GitHub

### Conocimientos Recomendados
- HTML, CSS y JavaScript básico
- Conceptos básicos de Node.js
- Flutter y Dart básico
- Git básico

---

## 🏗️ Parte 1: Configuración de Supabase

### Paso 1.1: Crear Proyecto en Supabase

1. Ve a supabase.com y crea una cuenta
2. Crea un nuevo proyecto:
   - **Nombre**: `flutter-login` (o el nombre que prefieras)
   - **Contraseña de base de datos**: Guárdala en un lugar seguro
   - **Región**: Selecciona la más cercana
3. Espera a que el proyecto se configure (~2 minutos)

### Paso 1.2: Obtener Credenciales

1. Ve a **Settings** → **API**
2. Copia y guarda:
   - **Project URL**: `https://xxxxxxxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6...`

### Paso 1.3: Configurar URL de Redirección

1. Ve a **Authentication** → **URL Configuration**
2. En **Redirect URLs**, agrega:
   ```
   https://tu-app-railway.up.railway.app
   ```
   > ⚠️ Esta URL la obtendrás después de desplegar en Railway

### Paso 1.4: Configurar Email Templates (Opcional)

1. Ve a **Authentication** → **Email Templates**
2. Selecciona **Reset Password**
3. Personaliza el email si lo deseas:

```html
<h2>Restablecer Contraseña</h2>
<p>Hola,</p>
<p>Haz clic en el siguiente enlace para restablecer tu contraseña:</p>
<p><a href="{{ .ConfirmationURL }}">Restablecer Contraseña</a></p>
<p>Si no solicitaste esto, ignora este email.</p>
```

---

## 🌐 Parte 2: Crear el Servidor Web (Node.js)

### Paso 2.1: Estructura del Proyecto

Crea la siguiente estructura de carpetas:

```
web_reset_password/
├── package.json
├── Procfile
├── server.js
├── .gitignore
└── public/
    ├── reset-password.html
    ├── styles.css
    └── app.js
```

### Paso 2.2: Crear package.json

```json
{
  "name": "reset-password",
  "version": "1.0.0",
  "description": "Password reset page for Flutter app",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=14.x"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Paso 2.3: Crear Procfile

```
web: node server.js
```

### Paso 2.4: Crear .gitignore

```
node_modules/
.env
npm-debug.log
.DS_Store
```

### Paso 2.5: Crear server.js

```javascript
const express = require("express");
const path = require("path");
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para logs
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Servir archivos estáticos
app.use(express.static(path.join(__dirname, "public")));

// Ruta principal
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "reset-password.html"));
});

// Ruta para reset-password
app.get("/reset-password", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "reset-password.html"));
});

// Health check para Railway
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// Capturar todas las demás rutas
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "reset-password.html"));
});

const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running on port ${PORT}`);
});

// Manejo de errores
server.on('error', (error) => {
  console.error('❌ Server error:', error);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
```

### Paso 2.6: Crear reset-password.html

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Restablecer Contraseña</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="header">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                </svg>
                <h1>Restablecer Contraseña</h1>
                <p class="subtitle">Ingresa tu nueva contraseña</p>
            </div>

            <form id="resetForm">
                <div class="form-group">
                    <label for="password">Nueva Contraseña</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        minlength="6"
                        placeholder="Mínimo 6 caracteres"
                    >
                </div>

                <div class="form-group">
                    <label for="confirmPassword">Confirmar Contraseña</label>
                    <input
                        type="password"
                        id="confirmPassword"
                        name="confirmPassword"
                        required
                        minlength="6"
                        placeholder="Repite tu contraseña"
                    >
                </div>

                <div id="error" class="error" style="display: none;"></div>
                <div id="success" class="success" style="display: none;"></div>

                <button type="submit" id="submitBtn" class="btn">
                    <span id="btnText">Restablecer Contraseña</span>
                    <span id="btnLoader" class="loader" style="display: none;"></span>
                </button>
            </form>

            <div class="footer">
                <a href="#" onclick="window.close(); return false;">Volver a la aplicación</a>
            </div>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
```

### Paso 2.7: Crear styles.css

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.container {
  width: 100%;
  max-width: 450px;
}

.card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 40px;
}

.header {
  text-align: center;
  margin-bottom: 32px;
}

.icon {
  width: 64px;
  height: 64px;
  color: #667eea;
  margin-bottom: 16px;
}

h1 {
  font-size: 28px;
  color: #1a202c;
  margin-bottom: 8px;
}

.subtitle {
  color: #718096;
  font-size: 14px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  font-weight: 500;
  color: #2d3748;
  margin-bottom: 8px;
  font-size: 14px;
}

input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.3s;
}

input:focus {
  border-color: #667eea;
  outline: none;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.error {
  background: #fed7d7;
  color: #c53030;
  padding: 12px;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 14px;
}

.success {
  background: #c6f6d5;
  color: #22543d;
  padding: 12px;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 14px;
}

.footer {
  text-align: center;
  margin-top: 24px;
}

.footer a {
  color: #667eea;
  text-decoration: none;
  font-size: 14px;
}

.footer a:hover {
  text-decoration: underline;
}

.loader {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

### Paso 2.8: Crear app.js

> ⚠️ **IMPORTANTE**: Reemplaza `SUPABASE_URL` y `SUPABASE_KEY` con tus credenciales

```javascript
// ============================================
// CONFIGURACIÓN - REEMPLAZA CON TUS CREDENCIALES
// ============================================
const SUPABASE_URL = 'https://TU_PROYECTO.supabase.co';
const SUPABASE_KEY = 'tu_anon_key_aqui';

// ============================================
// FUNCIONES AUXILIARES
// ============================================

// Obtener el token de acceso de la URL (Supabase lo envía en el hash)
function getAccessToken() {
  const hash = window.location.hash.substring(1);
  const params = new URLSearchParams(hash);
  return params.get('access_token');
}

// Mostrar mensaje de error
function showError(message) {
  const errorDiv = document.getElementById('error');
  errorDiv.textContent = message;
  errorDiv.style.display = 'block';
  document.getElementById('success').style.display = 'none';
}

// Mostrar mensaje de éxito
function showSuccess(message) {
  const successDiv = document.getElementById('success');
  successDiv.textContent = message;
  successDiv.style.display = 'block';
  document.getElementById('error').style.display = 'none';
}

// Mostrar/ocultar loader del botón
function setLoading(isLoading) {
  const btnText = document.getElementById('btnText');
  const btnLoader = document.getElementById('btnLoader');
  const submitBtn = document.getElementById('submitBtn');
  
  if (isLoading) {
    btnText.style.display = 'none';
    btnLoader.style.display = 'inline-block';
    submitBtn.disabled = true;
  } else {
    btnText.style.display = 'inline';
    btnLoader.style.display = 'none';
    submitBtn.disabled = false;
  }
}

// ============================================
// LÓGICA PRINCIPAL
// ============================================

// Manejar el envío del formulario
document.getElementById('resetForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const password = document.getElementById('password').value;
  const confirmPassword = document.getElementById('confirmPassword').value;
  
  // Validar que las contraseñas coincidan
  if (password !== confirmPassword) {
    showError('Las contraseñas no coinciden');
    return;
  }
  
  // Validar longitud mínima
  if (password.length < 6) {
    showError('La contraseña debe tener al menos 6 caracteres');
    return;
  }
  
  // Obtener el token de acceso
  const accessToken = getAccessToken();
  
  if (!accessToken) {
    showError('Token de acceso no válido. Por favor solicita un nuevo enlace.');
    return;
  }
  
  setLoading(true);
  
  try {
    // Llamar a la API de Supabase para actualizar la contraseña
    const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({
        password: password
      })
    });
    
    const data = await response.json();
    
    if (response.ok) {
      showSuccess('¡Contraseña restablecida con éxito! Ya puedes cerrar esta ventana.');
      document.getElementById('resetForm').reset();
      document.getElementById('submitBtn').disabled = true;
    } else {
      const errorMessage = data.error_description || data.message || 'Error al restablecer';
      showError(errorMessage);
    }
  } catch (error) {
    console.error('Error:', error);
    showError('Error de conexión. Por favor intenta nuevamente.');
  } finally {
    setLoading(false);
  }
});

// Verificar si hay un token válido al cargar la página
window.addEventListener('DOMContentLoaded', () => {
  const accessToken = getAccessToken();
  
  if (!accessToken) {
    showError('No se encontró un token válido. Por favor solicita un nuevo enlace.');
    document.getElementById('submitBtn').disabled = true;
  }
});
```

---

## 🧪 Parte 3: Probar Localmente

### Paso 3.1: Instalar Dependencias

```bash
cd web_reset_password
npm install
```

### Paso 3.2: Ejecutar el Servidor

```bash
npm start
```

### Paso 3.3: Verificar

1. Abre el navegador en `http://localhost:3000`
2. Deberías ver la página de restablecimiento
3. El mensaje de "Token no válido" es normal (no hay token en la URL)

---

## 🚀 Parte 4: Desplegar en Railway

### Paso 4.1: Crear Repositorio en GitHub

1. Ve a GitHub y crea un nuevo repositorio
2. Nombre: `reset-password-web`
3. Visibilidad: Público o Privado

### Paso 4.2: Subir Código a GitHub

```bash
cd web_reset_password
git init
git add .
git commit -m "Initial commit: Password reset web page"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/reset-password-web.git
git push -u origin main
```

### Paso 4.3: Configurar Railway

1. Ve a railway.app y crea una cuenta
2. Click en **"New Project"**
3. Selecciona **"Deploy from GitHub repo"**
4. Autoriza Railway para acceder a tu repositorio
5. Selecciona `reset-password-web`
6. Railway detectará automáticamente que es un proyecto Node.js

### Paso 4.4: Obtener URL Pública

1. Ve a **Settings** → **Domains**
2. Click en **"Generate Domain"**
3. Copia la URL generada

### Paso 4.5: Actualizar Supabase

1. Vuelve a Supabase → **Authentication** → **URL Configuration**
2. En **Redirect URLs**, agrega la URL de Railway

---

## 📱 Parte 5: Integración con Flutter

### Paso 5.1: Agregar Dependencias

En `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
```

### Paso 5.2: Inicializar Supabase

En `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://TU_PROYECTO.supabase.co',
    anonKey: 'tu_anon_key_aqui',
  );
  
  runApp(MyApp());
}

final supabase = Supabase.instance.client;
```

### Paso 5.3: Crear Función para Solicitar Reset

```dart
Future<void> requestPasswordReset(String email) async {
  await supabase.auth.resetPasswordForEmail(
    email,
    redirectTo: 'https://tu-app-railway.up.railway.app',
  );
}
```

### Paso 5.4: Crear Pantalla de "Olvidé mi Contraseña"

```dart
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _message = null;
    });
    
    try {
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://tu-app-railway.up.railway.app',
      );
      
      setState(() {
        _isSuccess = true;
        _message = 'Se ha enviado un enlace a tu correo electrónico';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error al enviar el correo. Intenta nuevamente.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restablecer Contraseña')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ingresa tu correo y te enviaremos un enlace.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_message != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _isSuccess ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _requestReset,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Enviar Enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
```

---

## 🔄 Parte 6: Flujo Completo

### Diagrama del Flujo

```
┌─────────────┐      1. Solicita reset      ┌─────────────┐
│   Flutter   │ ──────────────────────────▶ │   Supabase  │
│     App     │                             │    Auth     │
└─────────────┘                             └──────┬──────┘
                                                   │
                                            2. Envía email
                                                   │
                                                   ▼
                                            ┌─────────────┐
                                            │   Usuario   │
                                            │   (Email)   │
                                            └──────┬──────┘
                                                   │
                                         3. Click en enlace
                                                   │
                                                   ▼
┌─────────────┐     4. Nueva contraseña     ┌─────────────┐
│   Railway   │ ◀────────────────────────── │   Browser   │
│   (Web)     │                             │             │
└──────┬──────┘                             └─────────────┘
       │
       │ 5. Actualiza contraseña via API
       ▼
┌─────────────┐
│   Supabase  │
└─────────────┘
```

---

## 🐛 Parte 7: Solución de Problemas

### Error 502 en Railway

**Causa**: El servidor no está escuchando en el puerto correcto.

**Solución**: Asegúrate de usar `process.env.PORT`:
```javascript
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Token no válido

**Causa**: El hash de la URL no contiene el access_token.

**Solución**:
1. Verifica que la URL de redirección en Supabase sea correcta
2. Asegúrate de que el enlace del email no haya expirado (1 hora)

### El email no llega

**Posibles causas**:
1. Revisa la carpeta de spam
2. Verifica que el email esté registrado en Supabase
3. Revisa los logs en Supabase → Authentication → Logs

---

## ✅ Checklist Final

- [ ] Proyecto de Supabase creado
- [ ] Credenciales de API guardadas
- [ ] Servidor Node.js funcionando localmente
- [ ] Repositorio en GitHub creado
- [ ] Proyecto desplegado en Railway
- [ ] URL de Railway agregada en Supabase Redirect URLs
- [ ] Credenciales actualizadas en app.js
- [ ] Integración con Flutter funcionando
- [ ] Flujo completo probado

---

## 🎉 ¡Felicitaciones!

Has completado el taller de implementación de un sistema de restablecimiento de contraseña.

---

*Taller creado para el proyecto flutter_login*
*Fecha: Diciembre 2024*
