class CartsController < ApplicationController
  def show
    @cart = current_cart
  end

  def add_item
    @product = Product.find(params[:product_id])
    @cart = current_cart

    if @cart.add_product(@product, 1)
      respond_to do |format|
        format.html { redirect_to cart_path, notice: t("flash.product_added") }
        format.turbo_stream
      end
    else
      redirect_to product_path(@product), alert: t("flash.stock_error", product: @product.name, stock: @product.stock)
    end
  end

  def remove_item
    @product = Product.find(params[:product_id])
    @cart = current_cart
    @cart.remove_product(@product)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: t("flash.product_removed") }
      format.turbo_stream
    end
  end

  def update_item
    @product = Product.find_by!(id: params[:product_id])
    @cart = current_cart
    @cart_item = @cart.cart_items.find_by(product: @product)

    return redirect_to cart_path unless @cart_item

    new_quantity = params[:quantity].to_i

    if new_quantity <= 0
      @cart_item.destroy
    else
      @product.with_lock do
        @product.reload
        if new_quantity > @product.stock
          return redirect_to cart_path,
            alert: t("flash.stock_error", product: @product.name, stock: @product.stock)
        end

        @cart_item.update(quantity: new_quantity)
      end
    end

    redirect_to cart_path
  end
end
