<div class="row">
<div class="col-sm-8">
<p>CoNVaQ is a web tool for CNV-based association study between two groups of samples. The simple web interface allows you to quickly upload segmented CNV samples and search for variations that are overrepresented in a population. CoNVaQ provides two models for determining significance of genomic regions:</p>
<ul>
<li>A statistical model using Fisher's exact test.</li>
<li>A novel query-based model allowing you to specify which CNVRs are considered significant using simple queries, e.g. "find the largest region duplicated in ≥ 30% of cases and ≤ 5% of controls".</li>
</ul>
<p>Furthermore, CoNVaQ computes empirical p-values (called q-values) for matching regions by repeatedly executing the same query while randomly perturbing the sample populations. The q-value is the probability of finding a matching region of same length or longer, when the size of each group is preserved, but the samples are randomly distributed among groups. The position and type of the individual CNV segments are not changed by the perturbation.</p>

<p>For more information on how to use CoNVaQ, see our step-by-step guide or watch the screencast to the right.</p>
</div>
<div class="col-sm-4">
<h4>Screencast</h4>
<div class="embed-responsive embed-responsive-16by9" >
<iframe class="embed-responsive-item" width="560" height="315" src="https://www.youtube.com/embed/eaF_5sQsdDg" frameborder="0" allowfullscreen>
</iframe>
</div>
</div>
</div>

<div class="row">
<div class="col-sm-3 col-xs-6"><a href="images/screen1.png" target="_blank" class="thumbnail"><img src="images/screen1_thumb.png" class="img-responsive"></a></div>
<div class="col-sm-3 col-xs-6"><a href="images/screen2.png" target="_blank" class="thumbnail"><img src="images/screen2_thumb.png" class="img-responsive"></a></div>
<div class="col-sm-3 col-xs-6"><a href="images/screen3.png" target="_blank" class="thumbnail"><img src="images/screen3_thumb.png" class="img-responsive"></a></div>
<div class="col-sm-3 col-xs-6"><a href="images/screen4.png" target="_blank" class="thumbnail"><img src="images/screen4_thumb.png" class="img-responsive"></a></div>
</div>

## R package

CoNVaQ is also available as an R package. You can install the latest development version using devtools with:

```
devtools::install_github("SimonLarsen/convaq")
```

For a quick introduction on how to use the R package we refer to <a href="vignettes/introduction.html" target="_blank">this vignette</a>.

## Citation

If you use CoNVaQ in your research, we kindly ask you to cite the following publication:

```
Citation details to be announced.
```
