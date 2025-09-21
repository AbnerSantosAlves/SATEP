class ConfigurationModel {
  String id;
  String nome;
  String email;
  String telefone;
  String cpf;
  String endereco;


  String urlImage;

  ConfigurationModel({
    required this.id, 
    required this.nome, 
    required this.email, 
    required this.telefone, 
    required this.cpf, 
    required this.endereco,
    required this.urlImage
    });

    ConfigurationModel.fromMap(Map<String, dynamic> map): 
    id = map["id"], 
    nome = map["nome"], 
    email = map["email"], 
    telefone = map["telefone"], 
    cpf = map["cpf"],
    endereco = map["endereco"],
    urlImage = map["urlImage"];


    Map<String, dynamic> toMap(){
      return{
        "id": id,
        "nome": nome,
        "email": email,
        "telefone": telefone,
        "cpf": cpf,
        "urlImage": urlImage
      };
    }

}