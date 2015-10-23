// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require_tree .

var bc_regex = /^[a-z]{3}[a-z0-9]{3,6}$/i;

const DEFAULT_ERROR = 'Something nasty occurred. Write down what you did for Mojo Jojo and try again.';

$(document).ready(function(){

    $.ajaxSetup({
        headers: {
            clientOffset: ((new Date()).getTimezoneOffset() / 60)
        }
    });

    setTimeout(pollStatus, 0);

    $('#suggest-btn').click(function(){
        $(this).hide();
        $('#suggest-form').show();
        $('#suggest-title').focus();
    });

    $('#cancel-suggest').click(function(){
        hideSuggest();
    });

    $('#save-suggest').click(function(){
        $.ajax({
            url: '/suggest',
            method: 'post',
            data: { title: $('#suggest-title').val() },
            success: function(response){
                if(response.title){
                    addNote('Thanks for suggesting ' + response.title + '!');
                }
            },
            complete: function(){
                hideSuggest();
            }
        });
    });

});

function pollStatus(){
    $.get('/status').success(function(response){
        $('#total-games').text(response.total_games);
        $('#open-checkouts').text(response.open_checkouts);
        $('#longest-open-checkout').text(response.longest_open_checkout);

        setTimeout(pollStatus, 5000);
    });
}

function makeToken(n){
    if(!n){
        n = 10;
    }
    var text = '',
        possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for(var i=0; i < n; i++){
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}

/*
* success - green
* info - blue
* warning - yellow
* danger - red
* */
function addNote(text, status, dismissTime){
    if(!status){
        status = 'success';
    }
    if(!dismissTime){
        dismissTime = 5000;
    }
    var token = makeToken();
    $('#notification-bin').append(
        '<div class="row note alert alert-' + status + ' alert-dismissible" id="' + token + '">'
        + '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>'
        + '<div>'
        + text
        + '</div>'
        + '</div>'
    );
    setTimeout(function(){
        $('#' + token).animate({'opacity': '0.01'}).slideUp(500, function(){ $(this).remove() });
    }, dismissTime);
}

function hideSuggest(){
    $('#suggest-form').hide();
    $('#suggest-btn').show();
    $('#suggest-title').val('');
}