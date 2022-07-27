function edit_rule(rule_id){
    $.post("edit_rule.js", {id: rule_id});
}
window.edit_rule = edit_rule

function save_rule(rule_id){
    var params = {}
    params['id'] = rule_id
    params['description'] = $('#rule_description').val()
    params['track'] = $('input[name="track_options"]:checked').val();
    params['legacy'] = $('#legacy').is(":checked")
    $.post("save_rule.js", params);
}
window.save_rule = save_rule

function new_rule(){
    $.post("new_rule.js");
}
window.new_rule = new_rule