var homeModeSwitching = false;

$(document).ready(function(){
    if($('#home-page').length === 0){
        return;
    }

    $.get('/games', null, null, 'script');

    $('#checkout-mode-btn, #return-mode-btn, #search-mode-btn').mousedown(function(){
        homeModeSwitching = true;
    });

    $('#checkout-mode-btn, #return-mode-btn, #search-mode-btn').click(function(){
        var previousMode = $('#home-page').attr('data-checkout-mode');
        var mode = this.id == 'checkout-mode-btn' ? 'checkout' : (this.id == 'return-mode-btn' ? 'return' : 'search');
        $('#home-page').attr('data-checkout-mode', mode);
        $('#checkout-mode-btn').toggleClass('btn-primary', mode == 'checkout').toggleClass('btn-default', mode != 'checkout');
        $('#return-mode-btn').toggleClass('btn-primary', mode == 'return').toggleClass('btn-default', mode != 'return');
        $('#search-mode-btn').toggleClass('btn-primary', mode == 'search').toggleClass('btn-default', mode != 'search');
        $('#home-search-filters').toggle(mode == 'search');
        $('#games-table').toggle(mode == 'search');
        $('#checkout-activity').toggle(mode != 'search');
        $('#g-barcode').attr('placeholder', mode == 'search' ? 'Title, Publisher or Barcode' : (mode == 'checkout' ? "Scan GAME's barcode to checkout." : "Scan GAME's barcode to return."));
        $('#home-input-icon').toggleClass('glyphicon-tower', mode != 'search').toggleClass('glyphicon-search', mode == 'search');
        resetCheckout();
        if(previousMode == 'search' && mode != 'search'){
            $('#g-search')[0].reset();
            $('#g-search label').removeClass('active');
            $.get('/games', null, null, 'script');
        }
        homeModeSwitching = false;
    });

    $('#games-table').on('click', '.pagination a', function(event){
        event.preventDefault();
        $.get(this.href, null, null, 'script');
    });

});
