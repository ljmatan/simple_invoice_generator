# simple_invoice_generator

## 1. **General Info**

---

This Flutter web project aims to simplify the process of generating PDF invoices.

The website allows users to input and store the following information:

1. **The company information**

- Name
- Identification numbers
- Address
- Contact info,
- Bank account info

2. **Company client information**

- Name
- Identification number
- Address

3. **Itemized invoice details**

- Product or service name
- Sale amount
- Measure unit
- Price in EUR

This information can then be displayed alongside the generated invoice file.

## 2. **How to Run**

---

Unlike traditional HTML websites, Flutter web applications are single-page applications (SPAs)
that require a server to serve the necessary JavaScript and Dart code.

A web server acts as the intermediary between the browser and the Flutter web app,
handling routing, loading required resources, and communicating with the app's backend services.
Without a server, the Flutter web app's dynamic features won't function properly.

### Running from the build/web Folder

1. **Clone the repository to your local machine**

- `git clone <repository-url>`

2. **Navigate to the `build/web` directory**

- `cd <project-directory>/build/web`

3. **Start a local server**

- `flutter run -d web-server --web-port 8080`
- `php -S localhost:8080`
- `python -m SimpleHTTPServer 8080`
- `npm install -g http-server && http-server -p 8080`
- ...

3. **Navigate to the website**

- `http://localhost:8000`

### Installing Flutter SDK and Running the Project

1. **Clone or download the project repository**

- Clone the project repository using a Git client or download the ZIP archive.

2. **Install Flutter SDK**

- Download the Flutter SDK for your operating system from the official Flutter website (https://docs.flutter.dev/tools/sdk).
- Extract the downloaded SDK and add the flutter bin directory to your system's PATH environment variable.

3. **Navigate to the project directory**

- Open a terminal or command prompt and navigate to the project directory.

4. **Run the project**

- Compile the project for web using the command `flutter run -d web-server --web-port 8080`.

5. **Navigate to the website**

- Open a web browser and navigate to http://localhost:8080 to access the running application.

## 3. **Project Structure**

---

As can be seen below, this Flutter project is separated into three main sections: `models`, `services`, and `view`.

```txt
📁 simple_invoice_generator
│
├── 📁 assets
│       └── File assets (e.g., images, fonts)
│
├── 📁 lib
│   │   └── Flutter-specific files and folders
│   │
│   ├── 📁 models
│   │   └── JSON model classes
│   ├── 📁 services
│   │   └── Global project services
│   └── 📁 view
│       └── User interface declaration
│
├── 📁 scripts
│       └── Shell automation scripts
│
└── 📁 web
    │   └── Base website support files
```

## 4. **Dependencies**

---

- Dart, Flutter SDK
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [pdf](https://pub.dev/packages/pdf)
- [zxing_lib](https://pub.dev/packages/zxing_lib)

## 5. **Contributing**

---

Feel free to contribute by opening issues or submitting pull requests.

## 6. **License**

---

This project is licensed under the MIT License - see the `LICENSE` file for details.
