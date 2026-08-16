
if User.count.zero?
  User.create!(
    username: "alexandre",
    name: "Administrador",
    password: "senha",
    role: "administrador"
  )
  puts "[ACAL] Created initial admin user: alexandre"
end
