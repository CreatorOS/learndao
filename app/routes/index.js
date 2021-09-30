var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

router.get('/:view', (req, res) => {
  res.render(req.params.view);
})

module.exports = router;
