var lastBarcode;
var MAX_CHECKOUT_ACTIVITY_ITEMS = 5;

function addCheckoutActivity(message, level){
    if($('#home-page').length === 0){
        $.notify(message, level || 'info', 5000);
        return;
    }

    var $list = $('#checkout-activity-list');
    if(!$list.length){
        return;
    }

    $('<li>', {
        class: 'list-group-item ' + (level || 'info'),
        text: message
    }).prependTo($list);

    while($list.children().length > MAX_CHECKOUT_ACTIVITY_ITEMS){
        $list.children().last().remove();
    }

    if($('#home-page').attr('data-checkout-mode') !== 'search'){
        $('#checkout-activity').show();
    }
}

$(document).ready(function(){
    $('#g-barcode, #a-barcode').focus(function(){
        lastBarcode = $(this);
    });

    $('#g-barcode, #a-barcode').blur(function(){
        var barcode = $(this);
        var homeMode = $('#home-page').attr('data-checkout-mode');
        var isCheckoutOrReturnMode = !$('#home-page').length || homeMode === 'checkout' || homeMode === 'return';

        setTimeout(function(){
            if($('#suggest-form').is(':visible')){
                return;
            }
            if(isCheckoutOrReturnMode && barcode.is(':visible') && !barcode.prop('disabled')){
                barcode.focus();
            }
        }, 0);
    });

    // Use the page-specific checkout or return API when a game barcode is entered.
    $('#g-barcode').change(function(){
        var barcode_val = $(this).val();

        if($('#home-page').length > 0 && homeModeSwitching){
            return;
        }

        if($('#home-page').attr('data-checkout-mode') == 'search'){
            $('#g-search').submit();
            return;
        }

        if(!bc_regex.test(barcode_val)){
            addCheckoutActivity('Invalid barcode format! Barcode should be at least 3 characters long and only contain alphanumeric characters.', 'warning');
            $(this).val('');
            return;
        }
        gameBarcode(false);

        var checkoutMode = $('#checkout-page').length > 0 || $('#home-page').attr('data-checkout-mode') == 'checkout';
        var returnMode = $('#return-page').length > 0 || $('#home-page').attr('data-checkout-mode') == 'return';
        var statusRequest = checkoutMode ? $.post('/checkout/new', { g_barcode: barcode_val }) : $.post('/return', { barcode: barcode_val });

        statusRequest.success(function(response){
            if(response.errors){
                $.each(response.errors, function(k, v){
                    addCheckoutActivity(v, 'danger');
                });
                gameBarcode(true);
            }else if(returnMode){
                if(response.time){
                    addCheckoutActivity('Successfully returned ' + response.game + '!', 'success');
                }else if(response.storage_removed){
                    addCheckoutActivity('Removed ' + response.game + ' from storage.', 'warning');
                }else{
                    addCheckoutActivity(response.game + ' is not currently checked out.', 'warning');
                }
                resetCheckout();
            }else{
                if(checkoutMode && response.cleared){
                    addCheckoutActivity('Previously active checkout or loan cleared for ' + response.game + '.', 'warning');
                }
                $('#g-name').text('Checking out: ' + response.game)
                $('#home-page #g-name').show();
                $('#a-row').show();
                $('#a-barcode').focus();
            }
        }).error(function(){
            addCheckoutActivity(DEFAULT_ERROR, 'danger');
            gameBarcode(true);
        });
    });

    // Make a call to /attendee/status when a new barcode is entered.
    $('#a-barcode').change(function(){
        var barcode_val = $(this).val();

        if(!bc_regex.test(barcode_val)){
            addCheckoutActivity('Invalid barcode format! Barcode should be at least 3 characters long and only contain alphanumeric characters.', 'warning');
            $(this).val('');
            return;
        }
        attendeeBarcode(false);

        $.get('attendee/status', { barcode: barcode_val }).success(function(response){
            $.post('/checkout/new', { g_barcode: $('#g-barcode').val(), a_barcode: barcode_val }).success(function(response){
                if(response.errors){
                    $.each(response.errors, function(k, v){
                        addCheckoutActivity(v, 'danger');
                    });
                }else{
                    addCheckoutActivity('Successfully checked out ' + response.game + '!', 'success');
                    resetCheckout();
                }
            }).error(function(){
                addCheckoutActivity(DEFAULT_ERROR, 'danger');
            }).complete(function(){
                attendeeBarcode(true);
            });
        }).error(function(response){
            if(response.status == 400){
                saveAttendee();
            }else{
                addCheckoutActivity(DEFAULT_ERROR, 'danger');
                attendeeBarcode(true);
            }
        });
    });

    // Reset the view when the X button is clicked.
    $('#checkouts-x-btn').click(function(){
        resetCheckout();
    });

});

function gameBarcode(active){
    var barcode = $('#g-barcode');

    barcode.prop('disabled', !active);
    if(active){
        barcode.val('').focus();
    }
}

function attendeeBarcode(active){
    var barcode = $('#a-barcode');

    if(active){
        barcode.val('').focus();
    }
}

function restoreBarcodeFocus(){
    if(lastBarcode && lastBarcode.is(':visible') && !lastBarcode.prop('disabled')){
        lastBarcode.focus();
    }else{
        gameBarcode(true);
    }
}

// Submit new attendee information. On success, hide form and display new info.
function saveAttendee(){
    $.post('attendee/new', { barcode: $('#a-barcode').val() }).success(function(response){
        if(response.attendee){
            $.post('checkout/new', { g_barcode: $('#g-barcode').val(), a_barcode: $('#a-barcode').val() }).success(function(response){
                if(response.errors){
                    $.each(response.errors, function(k, v){
                        addCheckoutActivity(v, 'danger');
                    });
                }else{
                    addCheckoutActivity('Successfully checked out ' + response.game + '!', 'success');
                    resetCheckout();
                }
            }).error(function(){
                addCheckoutActivity(DEFAULT_ERROR, 'danger');
            }).complete(function(){
                attendeeBarcode(true);
            });
        } else {
            addCheckoutActivity(DEFAULT_ERROR, 'danger');
            attendeeBarcode(true);
        }
    }).error(function(){
        addCheckoutActivity(DEFAULT_ERROR, 'danger');
        attendeeBarcode(true);
    });
};

function resetCheckout(){
    gameBarcode(true);
    $('#g-name').text('');
    $('#home-page #g-name').hide();
    $('#g-barcode').val('');

    attendeeBarcode(false);
    $('#a-row').hide();
    $('#a-barcode').val('');
}