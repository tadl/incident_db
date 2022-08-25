function save_comment(comment_for, id){
    var params = {}
    params['description'] = $('#new_comment').val()
    params['comment_for'] = comment_for
    params['id'] = id
    $.post("/comments/save.js", params);
}
window.save_comment = save_comment

function edit_comment(id, comment_for, owner_id){
    var params = {}
    params['comment_for'] = comment_for
    params['owner_id'] = owner_id
    params['id'] = id
    $.post("/comments/edit.js", params);
}
window.edit_comment = edit_comment

function update_comment(id, comment_for, owner_id){
    var params = {}
    params['description'] = $('#editing_description').val()
    params['comment_for'] = comment_for
    params['owner_id'] = owner_id
    params['id'] = id
    $.post("/comments/update.js", params);
}
window.update_comment = update_comment

function delete_comment(id, comment_for, owner_id){
    var params = {}
    params['comment_for'] = comment_for
    params['owner_id'] = owner_id
    params['id'] = id
    $.post("/comments/delete.js", params);
}
window.delete_comment = delete_comment