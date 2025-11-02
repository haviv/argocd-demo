#!/bin/bash
set -e

echo "📦 Initializing Git Repository for Demo App"
echo "============================================="
echo ""

cd "$(dirname "$0")"

# Initialize git if not already initialized
if [ ! -d .git ]; then
    echo "🔧 Initializing Git repository..."
    git init
    echo "✅ Git initialized"
else
    echo "✅ Git repository already exists"
fi

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
.DS_Store
*.log
*.swp
*~
EOF
    echo "✅ Created .gitignore"
fi

# Add and commit files
echo ""
echo "📝 Committing demo app..."
git add .
git commit -m "Initial commit: ArgoCD demo app" || echo "✅ Files already committed"

echo ""
echo "=========================================="
echo "✅ Git repository ready!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Create a new GitHub repository (public or private)"
echo ""
echo "2. Push this code to GitHub:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/argocd-demo.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. OR use this local repo with ArgoCD:"
echo "   You can deploy directly from your local filesystem for testing!"
echo "   Just use: file://$(pwd)"
echo ""
echo "💡 For learning purposes, you can actually use the local filesystem"
echo "   as the 'Git repo' by using the file:// protocol in ArgoCD!"
echo ""

