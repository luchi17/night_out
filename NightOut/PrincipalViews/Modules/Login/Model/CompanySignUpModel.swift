import Foundation

struct CompanyModel: Codable {
    var email: String = ""
    var endTime: String = ""
    var selectedTag: String = ""
    var fullname: String? = ""
    var username: String? = ""
    var imageUrl: String?
    var location: String? = ""
    var startTime: String = ""
    var uid: String = ""
    var entradas: [String: EntradaModel] = [:]
    var payment: PaymentMethodModel?
    
    enum CodingKeys: String, CodingKey {
            case entradas
            case email
            case fullname
            case location
            case selectedTag = "selected_tag"
            case startTime = "start_time"
            case endTime = "end_time"
            case uid
            case username
            case payment = "Metodos_De_Pago"
            case imageUrl = "image"
        }
}

struct EntradaModel: Codable {
    var capacity: String = ""
    var description: String = ""
    var date: String = ""
    var imageUrl: String = ""
    var name: String? = ""
    var price: String? = ""
    
    enum CodingKeys: String, CodingKey {
            case capacity
            case description
            case date = "fecha"
            case imageUrl = "image_url"
            case name
            case price
        }
}

struct PaymentMethodModel: Codable {
    var accountHolderName: String = ""
    var accountType: String = ""
    var addressLine: String = ""
    var city: String = ""
    var country: String? = ""
    var dob: String? = ""
    var iban: String? = ""
    var postalCode: String? = ""
    var swift: String? = ""
    var taxId: String? = ""
}

//class SignUpCompanyActivity : AppCompatActivity() {
//
//    private lateinit var binding: ActivitySignUpCompanyBinding
//    private var imageUri: Uri? = null
//    private var typeprofile: String? = null
//
//    companion object {
//        private const val REQUEST_MAPS_SELECTION = 123
//        private const val REQUEST_IMAGE_SELECTION = 124
//    }

//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        binding = ActivitySignUpCompanyBinding.inflate(layoutInflater)
//        setContentView(binding.root)
//        typeprofile = intent.getStringExtra("profileType")
//
//        binding.signupBtn.setOnClickListener {
//            uploadImageAndUpdateInfo()
//        }
//
//        binding.selectPhotoBtn.setOnClickListener {
//            val intent = Intent(Intent.ACTION_PICK)
//            intent.type = "image/*"
//            startActivityForResult(intent, REQUEST_IMAGE_SELECTION)
//        }
//
//        binding.locationEditText.setOnClickListener {
//            openMapsActivity()
//        }
//    }

//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//        super.onActivityResult(requestCode, resultCode, data)
//        if (requestCode == REQUEST_MAPS_SELECTION && resultCode == RESULT_OK) {
//            val latitude = data?.getDoubleExtra("latitude", 0.0)
//            val longitude = data?.getDoubleExtra("longitude", 0.0)
//            if (latitude != null && longitude != null) {
//                binding.locationEditText.text = "$latitude,$longitude"
//            }
//        } else if (requestCode == REQUEST_IMAGE_SELECTION && resultCode == RESULT_OK && data != null) {
//            imageUri = data.data
//            binding.selectPhotoBtn.text = imageUri.toString()
//        }
//    }

//    private fun uploadImageAndUpdateInfo() {
//        if (imageUri != null && !TextUtils.isEmpty(binding.fullnameSignup.text.toString()) &&
//            !TextUtils.isEmpty(binding.usernameSignup.text.toString()) &&
//            !TextUtils.isEmpty(binding.emailSignup.text.toString()) &&
//            !TextUtils.isEmpty(binding.passwordSignup.text.toString())) {
//
//            val progressDialog = ProgressDialog(this@SignUpCompanyActivity)
//            progressDialog.setTitle("SignUp")
//            progressDialog.setMessage("Por favor espere, esto puede tardar unos momentos....")
//            progressDialog.setCanceledOnTouchOutside(false)
//            progressDialog.show()
//
//            val mAuth: FirebaseAuth = FirebaseAuth.getInstance()
//            mAuth.createUserWithEmailAndPassword(binding.emailSignup.text.toString(), binding.passwordSignup.text.toString())
//                .addOnCompleteListener { task ->
//                    progressDialog.dismiss()
//                    if (task.isSuccessful) {
//                        // Get the FCM token and upload image
//                        FirebaseMessaging.getInstance().token.addOnCompleteListener { tokenTask ->
//                            if (tokenTask.isSuccessful) {
//                                val token = tokenTask.result
//                                val storageRef = FirebaseStorage.getInstance().reference.child("profile_pictures/${mAuth.currentUser!!.uid}")
//                                storageRef.putFile(imageUri!!)
//                                    .addOnSuccessListener { taskSnapshot ->
//                                        storageRef.downloadUrl.addOnSuccessListener { uri ->
//                                            saveUserInfo(
//                                                binding.fullnameSignup.text.toString(),
//                                                binding.usernameSignup.text.toString(),
//                                                binding.emailSignup.text.toString(),
//                                                binding.locationEditText.text.toString(),
//                                                binding.startTimeButton.text.toString(),
//                                                binding.endTimeButton.text.toString(),
//                                                binding.selectTagBtn.text.toString(),
//                                                uri.toString(),
//                                                progressDialog,
//                                                token
//                                            )
//                                        }
//                                    }
//                                    .addOnFailureListener { e ->
//                                        showAlertDialog("Error", e.message ?: "Unknown error")
//                                    }
//                            } else {
//                                // Handle failure to get token
//                                showAlertDialog("Error", "Failed to get FCM token.")
//                            }
//                        }
//                    } else {
//                        val message = task.exception?.toString() ?: "Unknown error"
//                        showAlertDialog("Error", message)
//                        mAuth.signOut()
//                    }
//                }
//        } else {
//            showAlertDialog("Error", "Complete todos los campos y elija una foto de perfil.")
//        }
//    }
//
//    private fun openMapsActivity() {
//        val intent = Intent(this, MapSelectionActivity::class.java)
//        startActivityForResult(intent, REQUEST_MAPS_SELECTION)
//    }
//
//    private fun showTagSelectionDialog(tags: Array<String>) {
//        val builder = AlertDialog.Builder(this)
//        builder.setTitle("Elija etiqueta")
//        builder.setItems(tags) { dialog, which ->
//            val selectedTag = tags[which]
//            showAlertDialog("Etiqueta seleccionada", "Etiqueta seleccionada: $selectedTag") {
//                binding.selectTagBtn.text = selectedTag
//            }
//        }
//        val dialog = builder.create()
//        dialog.show()
//    }
//
//    private fun saveUserInfo(fullName: String, userName: String, email: String, location: String, startTime: String, endTime: String, selectedTag: String, selectedImageUri: String, progressDialog: ProgressDialog, token: String) {
//        val currentUserID = FirebaseAuth.getInstance().currentUser!!.uid
//        val usersRef: DatabaseReference = FirebaseDatabase.getInstance().reference.child("Company_Users")
//
//        val userMap = HashMap<String, Any>()
//        userMap["uid"] = currentUserID
//        userMap["fullname"] = fullName.lowercase()
//        userMap["username"] = userName.lowercase()
//        userMap["email"] = email
//        userMap["location"] = location
//        userMap["start_time"] = startTime
//        userMap["end_time"] = endTime
//        userMap["selected_tag"] = selectedTag
//        userMap["image"] = selectedImageUri
//        userMap["fcm_token"] = token // Add the FCM token here
//
//        usersRef.child(currentUserID).setValue(userMap)
//            .addOnCompleteListener { task ->
//                progressDialog.dismiss()
//                if (task.isSuccessful) {
//                    showAlertDialog("Exito", "Tu cuenta se creo correctamente.") {
//                        FirebaseDatabase.getInstance().reference
//                            .child("Follow").child(currentUserID)
//                            .child("Following").child(currentUserID)
//                            .setValue(true)
//
//                        val intent = Intent(this@SignUpCompanyActivity, MainActivity::class.java)
//                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
//                        intent.putExtra("profileType", "Company_User")
//                        startActivity(intent)
//                        finish()
//                    }
//                } else {
//                    val message = task.exception?.toString() ?: "Unknown error"
//                    showAlertDialog("Error", message)
//                    FirebaseAuth.getInstance().signOut()
//                }
//            }
//    }
//
//    private fun showAlertDialog(title: String, message: String, onPositiveButtonClicked: (() -> Unit)? = null) {
//        AlertDialog.Builder(this)
//            .setTitle(title)
//            .setMessage(message)
//            .setPositiveButton("OK") { dialog, _ ->
//                dialog.dismiss()
//                onPositiveButtonClicked?.invoke()
//            }
//            .create()
//            .show()
//    }
//}
