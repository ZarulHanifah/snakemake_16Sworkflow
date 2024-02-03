for i in 2 3 4 5 6 ; do
    unzip -j collapsed_table_l"$i".qza $(unzip -Z1 collapsed_table_l"$i".qza | grep "biom$")
    biom convert -i feature-table.biom -o feature_table_l"$i".tsv --to-tsv
    rm -rf feature-table.biom
done