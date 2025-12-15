class CheckoutsController < ApplicationController
  def create
    @cart = current_cart

    if @cart.cart_items.empty?
      redirect_to cart_path, alert: "Tu carrito está vacío"
      return
    end

    session = Stripe::Checkout::Session.create(
      payment_method_types: ["card"],
      mode: "payment",
      customer_email: current_user&.email,
      line_items: build_line_items(@cart),
      shipping_address_collection: {
        allowed_countries: shipping_countries
      },
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_checkout_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    if params[:session_id]
      @session = Stripe::Checkout::Session.retrieve(params[:session_id])

      # Crear la orden si no existe
      @order = Order.find_by(stripe_session_id: params[:session_id])

      if @order.nil?
        @order = Order.create!(
          user: current_user,
          cart: current_cart,
          status: :paid,
          total_cents: @session.amount_total,
          stripe_session_id: @session.id,
          email: @session.customer_details.email
        )

        # Enviar correo de confirmación
        OrderMailer.confirmation(@order).deliver_now

        # Limpiar el carrito
        current_cart.cart_items.destroy_all
        session.delete(:cart_secret_id)
      end
    end
  end

  def cancel
  end

  private

  def build_line_items(cart)
    cart.cart_items.includes(:product).map do |item|
      {
        price_data: {
          currency: "usd",
          unit_amount: item.product.price_cents,
          product_data: {
            name: item.product.name,
            description: item.product.category&.name
          }
        },
        quantity: item.quantity
      }
    end
  end

  def shipping_countries
  %w[
      AC AD AE AF AG AI AL AM AO AQ AR AT AU AW AX AZ
      BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ
      CA CD CF CG CH CI CK CL CM CN CO CR CV CW CY CZ
      DE DJ DK DM DO DZ EC EE EG EH ER ES ET
      FI FJ FK FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
      HK HN HR HT HU ID IE IL IM IN IO IQ IS IT
      JE JM JO JP KE KG KH KI KM KN KR KW KY KZ
      LA LB LC LI LK LR LS LT LU LV LY
      MA MC MD ME MF MG MK ML MM MN MO MQ MR MS MT MU MV MW MX MY MZ
      NA NC NE NG NI NL NO NP NR NU NZ OM
      PA PE PF PG PH PK PL PM PN PR PS PT PY QA
      RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SZ
      TA TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
      UA UG US UY UZ VA VC VE VG VN VU WF WS XK YE YT ZA ZM ZW ZZ
    ]
  end
end
