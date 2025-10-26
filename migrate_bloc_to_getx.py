#!/usr/bin/env python3
import os
import re

def migrate_file(filepath):
    """Migrate a single Dart file from BLoC to GetX"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Skip if file doesn't contain BLoC references
        if 'flutter_bloc' not in content and 'AuthenticationBloc' not in content and 'UserBloc' not in content:
            return False
        
        # Import replacements
        content = re.sub(
            r"import 'package:flutter_bloc/flutter_bloc\.dart';\s*\n",
            "",
            content
        )
        content = re.sub(
            r"import 'package:calai/app/modules/Auth/blocs/authentication_bloc/authentication_bloc\.dart';\s*\n",
            "import 'package:calai/app/controllers/auth_controller.dart';\n",
            content
        )
        content = re.sub(
            r"import 'package:calai/app/modules/Auth/blocs/my_user_bloc/my_user_bloc\.dart';\s*\n",
            "import 'package:calai/app/controllers/user_controller.dart';\n",
            content
        )
        content = re.sub(
            r"import 'package:calai/app/modules/Auth/blocs/my_user_bloc/my_user_state\.dart';\s*\n",
            "",
            content
        )
        content = re.sub(
            r"import 'package:calai/app/modules/Auth/blocs/sign_in_bloc/sign_in_bloc\.dart';\s*\n",
            "",
            content
        )
        
        # Add Get import if not present and BLoC was being used
        if "import 'package:get/get.dart';" not in content and ('AuthenticationBloc' in original_content or 'UserBloc' in original_content):
            # Find the last import statement
            import_pattern = r"(import '[^']+';)\s*\n(?!import)"
            match = list(re.finditer(import_pattern, content))
            if match:
                last_import_pos = match[-1].end()
                content = content[:last_import_pos] + "import 'package:get/get.dart';\n" + content[last_import_pos:]
        
        # Code pattern replacements
        replacements = [
            # Authentication state access
            (r"context\.read<AuthenticationBloc>\(\)\.state\.user", "Get.find<AuthController>().firebaseUser"),
            (r"context\.read<AuthenticationBloc>\(\)\.state", "Get.find<AuthController>()"),
            
            # Variable declarations
            (r"final authState = context\.read<AuthenticationBloc>\(\)\.state;", 
             "final authController = Get.find<AuthController>();"),
            
            # Condition checks
            (r"if \(authState\.user == null\)", "if (!authController.isAuthenticated)"),
            (r"if \(authState\.user != null\)", "if (authController.isAuthenticated)"),
            (r"authState\.user == null", "!authController.isAuthenticated"),
            (r"authState\.user != null", "authController.isAuthenticated"),
            
            # User ID access
            (r"authState\.user!\.uid", "authController.userId!"),
            (r"authState\.user\.uid", "authController.userId"),
            
            # BlocBuilder replacements
            (r"BlocBuilder<UserBloc,\s*UserState>", "GetBuilder<UserController>"),
            (r"BlocBuilder<AuthenticationBloc,\s*AuthenticationState>", "GetBuilder<AuthController>"),
            
            # User state checks
            (r"context\.read<UserBloc>\(\)\.state", "Get.find<UserController>()"),
            (r"userState is UserLoaded", "userController.hasUser"),
            (r"if \(userState is UserLoaded\)", "if (userController.hasUser)"),
            (r"userState\.userModel", "userController.userModel"),
            
            # BlocProvider replacements (less common but needed)
            (r"BlocProvider\.of<AuthenticationBloc>\(context\)", "Get.find<AuthController>()"),
            (r"BlocProvider\.of<UserBloc>\(context\)", "Get.find<UserController>()"),
        ]
        
        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content)
        
        # Special case: builder parameter name changes
        content = re.sub(
            r"GetBuilder<UserController>\(\s*builder:\s*\(context,\s*userState\)\s*\{",
            "GetBuilder<UserController>(\n  builder: (userController) {",
            content
        )
        content = re.sub(
            r"GetBuilder<UserController>\(\s*builder:\s*\(context,\s*state\)\s*\{",
            "GetBuilder<UserController>(\n  builder: (userController) {",
            content
        )
        content = re.sub(
            r"GetBuilder<AuthController>\(\s*builder:\s*\(context,\s*authState\)\s*\{",
            "GetBuilder<AuthController>(\n  builder: (authController) {",
            content
        )
        
        # Only write if changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            
            # Show what changed
            changes = []
            if 'flutter_bloc' in original_content and 'flutter_bloc' not in content:
                changes.append("removed flutter_bloc")
            if 'AuthenticationBloc' in original_content and 'AuthController' in content:
                changes.append("migrated AuthenticationBloc")
            if 'UserBloc' in original_content and 'UserController' in content:
                changes.append("migrated UserBloc")
            
            print(f"✅ {filepath.split('CalAI-App/')[-1]}")
            if changes:
                print(f"   └─ {', '.join(changes)}")
            return True
        return False
        
    except Exception as e:
        print(f"❌ Error: {filepath.split('CalAI-App/')[-1]} - {e}")
        return False

def main():
    """Main migration function"""
    base_path = "/Users/apple/Documents/Projects/CalAI/CalAI-App/lib"
    files_updated = 0
    files_scanned = 0
    
    print("🔍 Scanning for files with BLoC references...\n")
    
    # Find all Dart files
    for root, dirs, files in os.walk(base_path):
        # Skip generated files and build folders
        if any(skip in root for skip in ['generated', 'build', '.dart_tool', 'blocs']):
            continue
            
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                files_scanned += 1
                if migrate_file(filepath):
                    files_updated += 1
    
    print(f"\n" + "="*60)
    print(f"✅ Migration Complete!")
    print(f"   Files scanned: {files_scanned}")
    print(f"   Files updated: {files_updated}")
    print("="*60)
    
    print("\n📋 Next Steps:")
    print("   1. Run: cd /Users/apple/Documents/Projects/CalAI/CalAI-App")
    print("   2. Run: flutter clean")
    print("   3. Run: flutter pub get")
    print("   4. Update pubspec.yaml - remove flutter_bloc, bloc, equatable")
    print("   5. Delete folder: lib/app/modules/Auth/blocs/")
    print("   6. Test your app!")

if __name__ == "__main__":
    main()