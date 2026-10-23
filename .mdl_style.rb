# frozen_string_literal: true

all
rule "MD033", allowed_elements: "img"
# 既存コンテンツの書き方 (setext の h1 + atx の h2 以降、長い段落) に合わせます。
exclude_rule "MD003"
exclude_rule "MD013"
