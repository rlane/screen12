#include "mruby.h"
#include "mruby/proc.h"
#include "mruby/array.h"
#include "mruby/string.h"
#include "mruby/compile.h"
#include "mruby/dump.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

int
main(int argc, char **argv)
{
  mrb_state *mrb = mrb_open();

  if (mrb == NULL) {
    fprintf(stderr, "Invalid mrb_state, exiting mruby");
    return EXIT_FAILURE;
  }

  char *path = argv[1];
  FILE *file = fopen(path, "r");
  if (!file) {
    fprintf(stderr, "failed to open file\n");
    return 1;
  }

  mrbc_context *c = mrbc_context_new(mrb);
  mrbc_filename(mrb, c, path);
  struct mrb_parser_state *p = mrb_parse_file(mrb, file, c);
  mrbc_context_free(mrb, c);
  if (!p || !p->tree || p->nerr) {
    fprintf(stderr, "failed to parse file\n");
    return 1;
  }

  int n = mrb_generate_code(mrb, p->tree);
  if (n < 0) {
    fprintf(stderr, "failed to generate code\n");
    return 1;
  }

  mrb_parser_free(p);

  mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[n]), mrb_top_self(mrb));
  if (mrb->exc) {
    mrb_p(mrb, mrb_obj_value(mrb->exc));
  }

  return 0;
}
