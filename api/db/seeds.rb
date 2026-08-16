
if User.count.zero?
  User.create!(
    username: "alexandre",
    name: "Administrador",
    password: "senha",
    role: "administrador"
  )
end
