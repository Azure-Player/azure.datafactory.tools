# Option 1 (:::)
::: mermaid
graph LR
dataset.movie_dataflow_sink --> linkedService.BlobSampleData
dataset.movie_dataflow_source --> linkedService.BlobSampleData
dataflow.MovieDemo --> dataset.movie_dataflow_sink
dataflow.MovieDemo --> dataset.movie_dataflow_source
:::

# Option 2 (```)
``` mermaid
graph LR
dataset.movie_dataflow_sink --> linkedService.BlobSampleData
dataset.movie_dataflow_source --> linkedService.BlobSampleData
dataflow.MovieDemo --> dataset.movie_dataflow_sink
dataflow.MovieDemo --> dataset.movie_dataflow_source
```
