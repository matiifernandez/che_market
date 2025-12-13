class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def add_item
    @product = Product.find(params[:product_id])
    @cart = current_cart

    if @cart.add_product(@product, 1)
      respond_to do |format|
        format.html { redirect_to cart_path, notice: "#{@product.name} agregado al carrito" }
        format.turbo_stream
      end
    else
      redirect_to product_path(@product), alert: "No se pudo agregar el producto al carrito"
    end
  end

  def remove_item
    @product = Product.find(params[:product_id])
    @cart = current_cart
    @cart.remove_product(@product)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{@product.name} eliminado del carrito" }
      format.turbo_stream
    end
  end

  def update_item
    product_id = params[:product_id]
    Rails.logger.info "Product ID value: #{product_id.inspect}"

    @product = Product.find_by!(id: product_id)
    @cart = current_cart
    @cart_item = @cart.cart_items.find_by(product: @product)

    if @cart_item
      new_quantity = params[:quantity].to_i
      if new_quantity > 0
        @cart_item.update(quantity: new_quantity)
      else
        @cart_item.destroy
      end
    end

    redirect_to cart_path
  end
end
