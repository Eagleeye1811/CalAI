#!/usr/bin/env python3
import os
import re

def fix_file(filepath):
    """Fix GetX migration issues in a Dart file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Skip if no errors to fix
        if 'authController' not in content and 'userController' not in content:
            return False
        
        # Pattern 1: Fix methods that use authController but don't declare it
        # Find methods with authController usage
        pattern1 = r'((?:Future<[^>]+>|void)\s+\w+\([^)]*\)\s+(?:async\s+)?\{)\s*\n(\s+)(?!final authController)(.*?if\s*\(!\s*authController\.isAuthenticated)'
        
        def add_auth_declaration(match):
            method_start = match.group(1)
            indent = match.group(2)
            rest = match.group(3)
            return f'{method_start}\n{indent}final authController = Get.find<AuthController>();\n{indent}{rest}'
        
        content = re.sub(pattern1, add_auth_declaration, content, flags=re.MULTILINE)
        
        # Pattern 2: Fix methods that use userController
        pattern2 = r'((?:Future<[^>]+>|void)\s+\w+\([^)]*\)\s+(?:async\s+)?\{)\s*\n(\s+)(?!final userController)(.*?if\s*\(\s*userController\.hasUser)'
        
        def add_user_declaration(match):
            method_start = match.group(1)
            indent = match.group(2)
            rest = match.group(3)
            return f'{method_start}\n{indent}final userController = Get.find<UserController>();\n{indent}{rest}'
        
        content = re.sub(pattern2, add_user_declaration, content, flags=re.MULTILINE)
        
        # Pattern 3: Replace remaining context.read patterns
        content = re.sub(
            r'context\.read<AuthenticationBloc>\(\)',
            'Get.find<AuthController>()',
            content
        )
        content = re.sub(
            r'context\.read<UserBloc>\(\)',
            'Get.find<UserController>()',
            content
        )
        content = re.sub(
            r'context\.read<SignInBloc>\(\)',
            '// REMOVED: SignInBloc - implement auth logic differently',
            content
        )
        
        # Pattern 4: Fix GetBuilder builder parameters
        content = re.sub(
            r'GetBuilder<UserController>\(\s*builder:\s*\(context,\s*\w+\)\s*\{',
            'GetBuilder<UserController>(\n      builder: (userController) {',
            content
        )
        content = re.sub(
            r'GetBuilder<AuthController>\(\s*builder:\s*\(context,\s*\w+\)\s*\{',
            'GetBuilder<AuthController>(\n      builder: (authController) {',
            content
        )
        
        # Pattern 5: Remove BlocProvider references
        content = re.sub(
            r'BlocProvider<[^>]+>\(',
            '// REMOVED: BlocProvider(',
            content
        )
        content = re.sub(
            r'BlocProvider\.value\(',
            '// REMOVED: BlocProvider.value(',
            content
        )
        content = re.sub(
            r'BlocListener<[^>]+>\(',
            '// REMOVED: BlocListener(',
            content
        )
        
        # Pattern 6: Remove bloc event calls
        content = re.sub(
            r'\.add\((?:LoadUserModel|SignOutRequired|GoogleSignInRequested)\([^)]*\)\)',
            '// REMOVED: bloc event',
            content
        )
        
        # Pattern 7: Fix userBloc references in classes
        content = re.sub(
            r'late\s+AuthenticationBloc\s+authenticationBloc;',
            'late AuthController authController;',
            content
        )
        content = re.sub(
            r'late\s+UserBloc\s+userBloc;',
            'late UserController userController;',
            content
        )
        
        # Pattern 8: Ensure Get import exists
        if 'Get.find' in content and "import 'package:get/get.dart';" not in content:
            # Add import after first import
            content = re.sub(
                r"(import '[^']+';)\n",
                r"\1\nimport 'package:get/get.dart';\n",
                content,
                count=1
            )
        
        # Only write if changes made
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed: {filepath.split('CalAI-App/')[-1]}")
            return True
        return False
        
    except Exception as e:
        print(f"❌ Error: {filepath.split('CalAI-App/')[-1]} - {e}")
        return False

def main():
    lib_path = "/Users/apple/Documents/Projects/CalAI/CalAI-App/lib"
    files_fixed = 0
    
    print("🔧 Fixing GetX migration errors...\n")
    
    for root, dirs, files in os.walk(lib_path):
        if any(skip in root for skip in ['generated', 'build', '.dart_tool', 'blocs']):
            continue
            
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                if fix_file(filepath):
                    files_fixed += 1
    
    print(f"\n{'='*60}")
    print(f"✅ Fixes applied to {files_fixed} files!")
    print("="*60)
    print("\nNext: Run 'flutter clean && flutter pub get'")

if __name__ == "__main__":
    main()
