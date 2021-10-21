zip -r compress.zip report.html $(find results | grep "qzv" | grep -v "mock")
