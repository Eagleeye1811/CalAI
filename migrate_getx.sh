#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Starting BLoC to GetX migration..."
echo ""

files_updated=0
cd CalAI-App/lib

# Find all .dart files and process them
find . -name "*.dart" -type f | while read file; do
    # Skip generated files
    if [[ "$file" == *"/generated/"* ]] || [[ "$file" == *"/build/"* ]] || [[ "$file" == *"/blocs/"* ]]; then
        continue
    fi
    
    # Check if file contains BLoC references
    if grep -q "flutter_bloc\|AuthenticationBloc\|UserBloc" "$file"; then
        echo "Processing: $file"
        
        # Create backup
        cp "$file" "$file.backup"
        
        # Perform replacements
        sed -i '' "s|import 'package:flutter_bloc/flutter_bloc.dart';||g" "$file"
        sed -i '' "s|import 'package:CalAI/app/modules/Auth/blocs/authentication_bloc/authentication_bloc.dart';|import 'package:CalAI/app/controllers/auth_controller.dart';|g" "$file"
        sed -i '' "s|import 'package:CalAI/app/modules/Auth/blocs/my_user_bloc/my_user_bloc.dart';|import 'package:CalAI/app/controllers/user_controller.dart';|g" "$file"
        sed -i '' "s|import 'package:CalAI/app/modules/Auth/blocs/my_user_bloc/my_user_state.dart';||g" "$file"
        sed -i '' "s|import 'package:CalAI/app/modules/Auth/blocs/sign_in_bloc/sign_in_bloc.dart';||g" "$file"
        
        sed -i '' "s|final authState = context.read<AuthenticationBloc>().state;|final authController = Get.find<AuthController>();|g" "$file"
        sed -i '' "s|if (authState.user == null)|if (!authController.isAuthenticated)|g" "$file"
        sed -i '' "s|if (authState.user != null)|if (authController.isAuthenticated)|g" "$file"
        sed -i '' "s|authState.user!.uid|authController.userId!|g" "$file"
        sed -i '' "s|authState.user.uid|authController.userId|g" "$file"
        
        sed -i '' "s|BlocBuilder<UserBloc, UserState>|GetBuilder<UserController>|g" "$file"
        sed -i '' "s|BlocBuilder<AuthenticationBloc, AuthenticationState>|GetBuilder<AuthController>|g" "$file"
        sed -i '' "s|userState is UserLoaded|userController.hasUser|g" "$file"
        sed -i '' "s|userState.userModel|userController.userModel|g" "$file"
        
        # Add Get import if needed
        if ! grep -q "import 'package:get/get.dart';" "$file" && grep -q "Get.find\|GetBuilder" "$file"; then
            # Find first import line and add Get import after it
            sed -i '' "1,/^import/ s|^\(import .*\)$|\1\nimport 'package:get/get.dart';|" "$file"
        fi
        
        echo "✅ Updated: $file"
        ((files_updated++))
    fi
done

echo ""
echo "========================================"
echo "✅ Migration Complete!"
echo "   Files updated: $files_updated"
echo "========================================"
echo ""
echo "📋 Next Steps:"
echo "   1. Review changes (backups saved as .backup files)"
echo "   2. Update pubspec.yaml (remove flutter_bloc, bloc, equatable)"
echo "   3. Run: flutter clean && flutter pub get"
echo "   4. Delete: lib/app/modules/Auth/blocs/"
echo "   5. Test your app!"
