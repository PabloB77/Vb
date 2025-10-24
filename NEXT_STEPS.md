# Next Steps to Enable Google Sign-In

I have added the necessary code to your project to support Google Sign-In with Firebase. However, there are a few manual steps you need to complete in Xcode to make it work.

### 1. Add Swift Package Dependencies

Your project needs the `Firebase` and `GoogleSignIn` libraries. You can add them using Swift Package Manager in Xcode:

1.  Open your project in Xcode.
2.  Go to **File > Add Packages...**.
3.  In the search bar, enter the following URLs one by one and add them to your project:
    *   `https://github.com/firebase/firebase-ios-sdk.git`
        *   When prompted, select the following libraries:
            *   `FirebaseCore`
            *   `FirebaseAuth`
    *   `https://github.com/google/GoogleSignIn-iOS.git`
        *   When prompted, select `GoogleSignIn`

### 2. Add `GoogleService-Info.plist` to Your Project

I have created a `GoogleService-Info.plist` file in your project directory. You need to add this file to your Xcode project:

1.  In Xcode, open the Project Navigator (the left-hand sidebar).
2.  Drag the `GoogleService-Info.plist` file from your Finder into the `AppTest` group in the Project Navigator.
3.  When prompted, make sure that "Copy items if needed" is checked and that your app's target is selected.

### 3. Configure a Custom URL Scheme

Google Sign-In requires a custom URL scheme to redirect back to your app after the user authenticates.

1.  In Xcode, select your project in the Project Navigator.
2.  Select your app's target.
3.  Go to the **Info** tab.
4.  Expand the **URL Types** section.
5.  Click the **+** button to add a new URL type.
6.  In the **URL Schemes** box, you need to enter the `REVERSED_CLIENT_ID` from your `GoogleService-Info.plist` file. Open the `GoogleService-Info.plist` file to find this value. It will look something like `com.googleusercontent.apps.1234567890-abcdefg`.

### 4. Add a Google Logo to Your Assets

The custom "Sign in with Google" button uses an image named `google_logo`. You'll need to find a suitable Google logo image and add it to your `Assets.xcassets` file.

1.  Find a Google logo image (e.g., a PNG file).
2.  In Xcode, open `AppTest/Assets.xcassets`.
3.  Drag the image file into the asset catalog.
4.  Rename the image set to `google_logo`.

Once you have completed these steps, you should be able to build and run the app, and you will see the Google Sign-In button.
