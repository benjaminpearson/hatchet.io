function hash() {
	var output = '';
	var chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
	for (i = 1; i < 50; i++) {
		var c = Math.floor(Math.random()*chars.length + 1);
		output += chars.charAt(c);
	}
	return output;
}

module.exports = {
	hash: hash
};