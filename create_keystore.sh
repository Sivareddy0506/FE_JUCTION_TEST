#!/bin/bash
# Script to create a new Android keystore

set -e

KEYSTORE_NAME="junction_new.jks"
KEYSTORE_PATH="$(pwd)/$KEYSTORE_NAME"
KEY_ALIAS="junction_key"
STORE_PASSWORD="junction123"
KEY_PASSWORD="junction123"
VALIDITY_DAYS=10000

echo "🔐 Creating New Android Keystore"
echo "=================================================="
echo ""
echo "Keystore file: $KEYSTORE_PATH"
echo "Alias: $KEY_ALIAS"
echo "Validity: $VALIDITY_DAYS days"
echo ""

# Try to find keytool
KEYTOOL_CMD=""

# Method 1: Check if keytool is in PATH
if command -v keytool &> /dev/null; then
    KEYTOOL_CMD="keytool"
    echo "✅ Found keytool in PATH"
fi

# Method 2: Try to use Java from Android SDK
if [ -z "$KEYTOOL_CMD" ] && [ -d "$HOME/Library/Android/sdk/jbr" ]; then
    KEYTOOL_CMD="$HOME/Library/Android/sdk/jbr/bin/keytool"
    if [ -f "$KEYTOOL_CMD" ]; then
        echo "✅ Found keytool in Android SDK"
    else
        KEYTOOL_CMD=""
    fi
fi

# Method 3: Try to find Java and use its keytool
if [ -z "$KEYTOOL_CMD" ]; then
    JAVA_HOME_VAR=$(/usr/libexec/java_home 2>/dev/null || echo "")
    if [ -n "$JAVA_HOME_VAR" ]; then
        KEYTOOL_CMD="$JAVA_HOME_VAR/bin/keytool"
        if [ -f "$KEYTOOL_CMD" ]; then
            echo "✅ Found keytool via JAVA_HOME"
        else
            KEYTOOL_CMD=""
        fi
    fi
fi

if [ -z "$KEYTOOL_CMD" ] || [ ! -f "$KEYTOOL_CMD" ]; then
    echo "❌ keytool not found. Please ensure Java is installed."
    echo ""
    echo "You can install Java by:"
    echo "  1. Installing Android Studio (includes Java)"
    echo "  2. Installing OpenJDK: brew install openjdk"
    echo ""
    echo "Alternatively, you can create the keystore manually:"
    echo "  keytool -genkey -v -keystore $KEYSTORE_NAME \\"
    echo "    -alias $KEY_ALIAS -keyalg RSA -keysize 2048 \\"
    echo "    -validity $VALIDITY_DAYS -storepass $STORE_PASSWORD \\"
    echo "    -keypass $KEY_PASSWORD \\"
    echo "    -dname \"CN=Junction, OU=Development, O=Junction, L=City, ST=State, C=US\""
    exit 1
fi

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore file already exists: $KEYSTORE_PATH"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -f "$KEYSTORE_PATH"
fi

# Create the keystore
echo "Creating keystore..."
$KEYTOOL_CMD -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Junction, OU=Development, O=Junction, L=City, ST=State, C=US" \
    2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore created successfully!"
    echo ""
    
    # Create key.properties file
    KEY_PROPERTIES_FILE="android/key.properties"
    cat > "$KEY_PROPERTIES_FILE" << EOF
storeFile=../../$KEYSTORE_NAME
keyAlias=$KEY_ALIAS
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
EOF
    
    echo "✅ Created $KEY_PROPERTIES_FILE"
    echo ""
    echo "📝 Keystore Information:"
    echo "   File: $KEYSTORE_PATH"
    echo "   Alias: $KEY_ALIAS"
    echo "   Store Password: $STORE_PASSWORD"
    echo "   Key Password: $KEY_PASSWORD"
    echo ""
    echo "⚠️  IMPORTANT: Save these credentials securely!"
    echo "   You'll need them for all future app updates."
    echo ""
    echo "✅ Ready to build! Run: flutter build appbundle"
else
    echo "❌ Failed to create keystore"
    exit 1
fi

