# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# frozen_string_literal: true

puts "Limpiando base de datos..."
LineItem.destroy_all if defined?(LineItem)
Order.destroy_all if defined?(Order)
CartItem.destroy_all if defined?(CartItem)
Cart.destroy_all if defined?(Cart)
Product.destroy_all
Category.destroy_all
User.destroy_all
Coupon.destroy_all if defined?(Coupon)

puts "Creando usuario admin..."
admin = User.new(
  email: "admin@chemarket.com",
  password: "password123",
  first_name: "Admin",
  last_name: "Che Market",
  role: :admin
)
admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
admin.save!

puts "Creando categorías..."
categories = {
  yerba: Category.create!(name: "Yerba Mate"),
  dulces: Category.create!(name: "Dulces"),
  mates: Category.create!(name: "Mates y Bombillas"),
  alfajores: Category.create!(name: "Alfajores"),
  bebidas: Category.create!(name: "Bebidas"),
  snacks: Category.create!(name: "Snacks")
}

puts "Creando productos..."

# Yerbas
Product.create!(
  name: "Yerba Mate Playadito 1kg",
  description: "La yerba mate más vendida de Argentina. Sabor suave y rendidor, ideal para todo el día.",
  price: 12.99,
  stock: 100,
  category: categories[:yerba],
  active: true
)

Product.create!(
  name: "Yerba Mate Taragüi 1kg",
  description: "Clásica yerba mate argentina con palo. Sabor intenso y tradicional.",
  price: 11.99,
  stock: 80,
  category: categories[:yerba],
  active: true
)

Product.create!(
  name: "Yerba Mate Rosamonte 1kg",
  description: "Yerba mate premium con estacionamiento natural. Sabor fuerte y con cuerpo.",
  price: 13.99,
  stock: 60,
  category: categories[:yerba],
  active: true
)

Product.create!(
  name: "Yerba Mate La Merced Campo Sur 500g",
  description: "Yerba mate premium de origen controlado. Notas herbales y frescas.",
  price: 9.99,
  stock: 40,
  category: categories[:yerba],
  active: true
)

# Dulces
Product.create!(
  name: "Dulce de Leche La Serenísima 400g",
  description: "El auténtico dulce de leche argentino. Cremoso y con el punto justo de dulzor.",
  price: 8.99,
  stock: 50,
  category: categories[:dulces],
  active: true
)

Product.create!(
  name: "Dulce de Leche Havanna 450g",
  description: "Dulce de leche premium, ideal para repostería o comer con cuchara.",
  price: 12.99,
  stock: 30,
  category: categories[:dulces],
  active: true
)

Product.create!(
  name: "Membrillo La Campagnola 500g",
  description: "Dulce de membrillo tradicional. Perfecto con queso para un postre vigilante.",
  price: 6.99,
  stock: 45,
  category: categories[:dulces],
  active: true
)

# Mates y Bombillas
Product.create!(
  name: "Mate de Calabaza Imperial",
  description: "Mate artesanal de calabaza con virola de alpaca. Curado y listo para usar.",
  price: 34.99,
  stock: 25,
  category: categories[:mates],
  active: true
)

Product.create!(
  name: "Mate de Vidrio con Funda de Cuero",
  description: "Mate térmico de vidrio con funda de cuero. Moderno y práctico.",
  price: 29.99,
  stock: 35,
  category: categories[:mates],
  active: true
)

Product.create!(
  name: "Bombilla de Alpaca Cincelada",
  description: "Bombilla artesanal de alpaca con diseños tradicionales. Pico desmontable.",
  price: 19.99,
  stock: 50,
  category: categories[:mates],
  active: true
)

Product.create!(
  name: "Kit Matero Completo",
  description: "Incluye mate de calabaza, bombilla de alpaca, yerbera y azucarera. Todo en un estuche de cuero.",
  price: 79.99,
  stock: 15,
  category: categories[:mates],
  active: true
)

# Alfajores
Product.create!(
  name: "Alfajores Havanna x 12",
  description: "Caja de 12 alfajores Havanna de chocolate con dulce de leche.",
  price: 24.99,
  stock: 40,
  category: categories[:alfajores],
  active: true
)

Product.create!(
  name: "Alfajores Cachafaz x 6",
  description: "Alfajores de maicena bañados en chocolate. Rellenos de dulce de leche.",
  price: 14.99,
  stock: 55,
  category: categories[:alfajores],
  active: true
)

Product.create!(
  name: "Alfajores Jorgito x 12",
  description: "Clásicos alfajores de maicena con dulce de leche. Sabor de la infancia.",
  price: 18.99,
  stock: 60,
  category: categories[:alfajores],
  active: true
)

# Bebidas
Product.create!(
  name: "Fernet Branca 750ml",
  description: "El amargo italiano que los argentinos hicieron propio. Ideal con Coca-Cola.",
  price: 28.99,
  stock: 30,
  category: categories[:bebidas],
  active: true
)

Product.create!(
  name: "Hesperidina 1L",
  description: "Licor de naranja argentino, el más antiguo del país. Dulce y aromático.",
  price: 22.99,
  stock: 20,
  category: categories[:bebidas],
  active: true
)

# Snacks
Product.create!(
  name: "Maní con Chocolate Georgalos 100g",
  description: "Maní tostado cubierto de chocolate con leche. Adictivo.",
  price: 5.99,
  stock: 80,
  category: categories[:snacks],
  active: true
)

Product.create!(
  name: "Pepas de Membrillo x 12",
  description: "Galletitas rellenas de membrillo. Un clásico de la merienda argentina.",
  price: 4.99,
  stock: 70,
  category: categories[:snacks],
  active: true
)

Product.create!(
  name: "Criollitas x 3 paquetes",
  description: "Galletitas de agua ideales para el mate. Crocantes y sabrosas.",
  price: 6.99,
  stock: 90,
  category: categories[:snacks],
  active: true
)

puts "Creando cupones de ejemplo..."

Coupon.create!(
  code: "BIENVENIDO10",
  discount_type: :percentage,
  discount_percentage: 10,
  active: true
)

Coupon.create!(
  code: "VERANO20",
  discount_type: :percentage,
  discount_percentage: 20,
  minimum_purchase_cents: 5000,
  active: true
)

Coupon.create!(
  code: "ENVIOGRATIS",
  discount_type: :fixed_amount,
  discount_amount_cents: 1000,
  active: true
)

puts "Seeds completados!"
puts "   - #{Category.count} categorias"
puts "   - #{Product.count} productos"
puts "   - #{User.count} usuarios"
puts "   - #{Coupon.count} cupones"
puts ""
puts "Admin: admin@chemarket.com / password123"
puts ""
puts "Cupones de prueba:"
puts "   - BIENVENIDO10 (10% off)"
puts "   - VERANO20 (20% off, min $50)"
puts "   - ENVIOGRATIS ($10 off)"
