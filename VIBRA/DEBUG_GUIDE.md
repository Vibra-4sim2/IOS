# 🔍 Guide de Debug - HomeView avec API

## ✅ Fichiers créés et configurés :

1. ✅ `Models/Ride.swift` - Modèle pour les sorties
2. ✅ `Models/RideWithCreator.swift` - Wrapper ride + creator
3. ✅ `Services/HomeService.swift` - Service API
4. ✅ `ViewModels/HomeViewModel.swift` - ViewModel
5. ✅ `Views/RideCardView.swift` - Composant de carte
6. ✅ `Views/HomeView.swift` - Vue principale

## 🔧 Étapes de diagnostic :

### 1. Vérifier que votre backend est démarré
```bash
# Dans le terminal de votre backend Node.js :
npm start
# ou
node server.js
```

Vérifiez que le serveur affiche quelque chose comme :
```
Server running on port 3000
```

### 2. Tester l'API manuellement
```bash
# Dans un terminal, testez l'endpoint :
curl http://localhost:3000/sorties

# Vous devriez voir un JSON avec vos sorties
```

### 3. Vérifier les logs dans Xcode

Quand vous lancez l'app, ouvrez la **Console de debug** dans Xcode :
- Menu : View → Debug Area → Activate Console (ou ⇧⌘C)

Vous devriez voir des logs comme :
```
🔄 HomeViewModel: Starting to load rides...
🌐 HomeService: Fetching rides from http://localhost:3000/sorties
📡 HomeService: Response status code - 200
📄 HomeService: Raw JSON response - [{"_id":"...","titre":"..."}]
✅ HomeService: Successfully decoded 3 rides
✅ HomeViewModel: Successfully fetched 3 rides
```

### 4. Si vous voyez une erreur de connexion :

#### ❌ "Failed to connect" ou "Connection refused"
**Solution** : Votre backend n'est pas démarré
```bash
cd /chemin/vers/votre/backend
npm start
```

#### ❌ "Invalid URL" 
**Solution** : Vérifiez `Constants.baseURL` dans `VIBRA/Utils/Constants.swift`

#### ❌ "Decoding error"
**Solution** : Le JSON de votre API ne correspond pas au modèle
- Regardez le log `📄 HomeService: Raw JSON response` dans la console
- Comparez avec le modèle `Ride.swift`

### 5. Si vous utilisez le simulateur iOS :

Le simulateur ne peut pas accéder à `localhost`, utilisez plutôt :
```swift
// Dans Constants.swift, changez :
static let baseURL = "http://127.0.0.1:3000"
// ou l'adresse IP de votre Mac :
static let baseURL = "http://192.168.x.x:3000"
```

Pour trouver votre IP Mac :
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### 6. Rebuild complet du projet :

Dans Xcode :
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)
3. Relancez l'app

## 🎯 Ce que vous devriez voir :

### Pendant le chargement :
- Un spinner blanc au centre

### En cas de succès :
- Des cartes avec :
  - Photo de la sortie
  - Titre
  - "by [Prénom du créateur]"
  - Badge du type (CAMPING, RANDONNÉE, VÉLO)
  - Distance
  - Avatar du créateur

### En cas d'erreur :
- Un message d'erreur en rouge avec les détails

## 🚨 Problèmes courants :

### "Erreur de chargement: The operation couldn't be completed"
→ Backend non démarré ou URL incorrecte

### "Erreur de chargement: The data couldn't be read"
→ Problème de décodage JSON (structure différente)

### Aucun message (ni spinner ni erreur)
→ Le ViewModel n'est peut-être pas initialisé correctement
→ Vérifiez que vous utilisez bien `@StateObject` dans HomeView

## 📞 Support :

Si le problème persiste, partagez :
1. Les logs de la console Xcode (copier/coller les messages avec 🔄 🌐 📡 ❌ ✅)
2. Un exemple de JSON retourné par votre API `GET /sorties`
3. La version de votre backend (Node.js, version)
